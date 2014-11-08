require 'bunny' 
module Cenit
  class Rabbit
    # ----------------------------------------------------------------------------------------------------------------------------
    # The general schema for rabbit_mq/bunny plumbing is the following:
    #
    # ------- First part --------------     ------------------- Second part ------------------------------------------------------  
    # |                               |     |                                                                                    |  
    # V                               V     V                                                                                    V 
    #
    #                                        (account X - event Y)Queue 1 --> Consumer 1 process flow and the result is requested 
    #                                        ^                             .  to endpoint 1 with webhook. Response is notified.
    #                                       /                              .
    #                                      /                               .                 
    #                                     /->(account X - event Y)Queue n --> Consumer n process flow and the result is requested 
    #                                    /  .                                 to endpoint n with webhook. Response is notified.
    #                                   /   .                                                
    #                                  /    .
    # direct exchange "cenit_classifier"    .                             
    #                                  \    .                                               
    #                                   \   .                                                
    #                                    \->(account V - event W)Queue m --> Consumer m process flow and the result is requested
    #                                     \                               .  to endpoint m with webhook. Response is notified.
    #                                      \                              .
    #                                       V                             .
    #                                       (account V - event W)Queue p --> Consumer p process flow and the result is requested
    #                                                                  to endpoint p with webhook. Response is notified.    

    @@conn = Bunny.new
    @@conn.start
    
    # This method is called at the end of the class, so the configuration become effective
    def self.startup   
      puts "\n\nCenit startup \n" 

      # First Part: Direct Exchange "cenit_classifier" creation ------------------------------------------------------------------
      # There is a direct exchange(see http://www.rabbitmq.com/tutorials/tutorial-four-ruby.html)
      # All messages will be sended to this exchange
      # This exchange will route the messages depending on their :routing_key attribute
      # The :routing_key attribute of a message is a string with the format 
      # account_id=<account_id>&event_id=<event_id>
      # So, when the event CREATE y hired for a Product object, it must be notified to RabbitMQ 
      # throught this exchange publishing a message with 
      # :routing_key => "account_id=12345678&event_id=87654321"
      # Ex: CLASSIFIER.publish(object, :routing_key => "account_id=12345678&event_id=87654321")
      # The method routing_key_for is used for formatting the routing_key         

      @@classifier = @@conn.create_channel.direct('cenit_classifier') 
        
      puts " * Created 'cenit_classifier' direct exchange\n" 
         
      # Second part: Parallel consuming ------------------------------------------------------------------------------------------
      # 'cenit_classifier' will publish messages to queues interested in routing_key, and consumer will consume messages from the
      # queue they are listening on.
      # We need parallel consuming. We need all consumer interested in a message they could consume the message.
      # The solution is create as queues as consumers, so each consumer will listen to only one queue
      # (see http://www.rabbitmq.com/tutorials/tutorial-three-ruby.html and http://www.rabbitmq.com/tutorials/tutorial-four-ruby.html).
      # There is a hash of consumer threads. We are using a hash for easy management of threads depending on the account, event & flow.   
      Account.all.each do |account| 
        Account.current = account
        
        puts " * Starting up Account: '%s'\n" % [account.name]
        consumer_threads[account.id] = {} 
        
        Setup::Flow.where(active: true).to_a.each {|for_flow| add_new_consumer for_flow }
      end
      
      puts "Cenit ready!!!\n"
      binding.pry
    end
    
    def self.consumer_threads
      @@consumer_threads ||= {}
      @@consumer_threads
    end
    
    # It is expected a flow
    def self.add_new_consumer(flow)
      if flow 
        c_threads = consumer_threads
        c_threads[flow.account.id] ||= {}
        c_threads[flow.account.id][flow.event.id] ||= {}

        for_flow = flow
        c_threads[flow.account.id][flow.event.id][flow.id] = new_sender_thread for_flow
        puts "        - Flow '%s' listening for event '%s %s'\n" % [flow.name, flow.event.model.name, flow.event.name] 
      end
    end

    # It is expected a flow
    # Returns a Thread
    def self.new_sender_thread(f)
      Thread.new(f) do |flow|
        cnx = Bunny.new
        cnx.start

        ch  = cnx.create_channel        
        q   = ch.queue("", :exclusive => true, :routing_key => routing_key_for(flow.event))

        q.bind classifier_exchange

        webhook    = flow.webhook
        connection = webhook.connection
        puts "   -[x] Consumer thread listening :routing_key => %s for request %s \n" % [routing_key, webhook.absolute_path]
      
        begin
          q.subscribe(:block => true) do |delivery_info, properties, object|

            puts " Consumming object %s.....\n" % [body]

            processed_object = flow.process(object)
            puts " Processed object: %s .....\n" % [processed_object]
            puts " Sending to endpoint .....\n"
            
            send_to_endpoint_and_notify_response :flow => flow, :object => processed_object, :original_object => object
          end
        rescue Exception => _
          puts _.message
        ensure
          ch.close
          cnx.close
        end
      end
    end
    
    # It is expected an event
    # Returns a string formatted: "account_id=#{event.account.id}&event_id=#{event.id}"
    def self.routing_key_for(event)
      "account_id=%s&event_id=%s" % [event.account.id.to_s, event.id.to_s]
    end

    def self.classifier_exchange
      @@classifier
    end

    def self.send_to_endpoint_and_notify_response(h)
      begin
        response = send_to_end_point(h)
        puts "\nResponse from: %s\n code: %s\n message: %s\n" % [h[:flow].webhook.connection.name, response.code, response.message]
        notify_response(response, h)
      rescue Exception => exc
        notify_response(response, h, exc.message)
      end
    end
    
    def self.send_to_end_point(h)
        flow       = h[:flow]
        webhook    = flow.webhook
        connection = webhook.connection

        puts "\nCenit sending to: %s\n url: %s\n object: %s\n" % [connection.name, webhook.absolute_path, h[:object]]
        return HTTParty.post(webhook.absolute_path, { body:    h[:object],
                                                      headers: { 'Content-Type'    => 'application/json',
                                                                 'X_HUB_STORE'     => connection.key,
                                                                 'X_HUB_TOKEN'     => connection.authentication_token,
                                                                 'X_HUB_TIMESTAMP' => Time.now.utc.to_i.to_s } } )
    end

    def self.notify_response(response, h, exception = nil)
      # This is for identify if the same object have been sended many times, due to errors
      # The trio (flow, object, original_object) must be unique for any notification
      # Could it be possible?? Must be investigated
      notif = Setup::Notification.where(:flow => h[:flow], :object => h[:object], :original_object => h[:original_object]).first
      
      notif, notif.count = notif ? [notif, notif.count + 1] : [Setup::Notification.new(h), 0]

      notif.http_status_code, notif.http_status_message = exception ? [nil, exception.message] : [response.code, response.message]

      notif.save!
    end

    def self.remove_consumer(flow)
      exists_thread = flow && consumer_threads[flow.account.id] && consumer_threads[flow.account.id][flow.event.id]
      consumer_threads[flow.account.id][flow.event.id][flow.id] = nil if exists_thread
    end

    def self.publish(message, event)
      classifier_exchange.publish(message, :routing_key => routing_key_for(event)) if event
    end  
  end
end
