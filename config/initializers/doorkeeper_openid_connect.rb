
Doorkeeper::OpenidConnect.configure do

  jws_private_key <<eol
-----BEGIN RSA PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDHonFxolrrDZKe
AfIBzGjQVmTmS1Ghw6tEkyIXvrTAVvxSBfO4PcgPDcrECnQJ/6M6/313RMXF3bs5
FY1rwwR7BYrM5ABfjQYqt03ShAhsrnYs6Mf0bMqbgH7piu8g1sWg4WB/d1CWxInK
Yn2huR/YXJUGfc/BEgcw3mcI53+CwQCR/6/LhRfwq90dbltqjkuZy25ZJzo4wEdp
YfC+H9NFwmDXXR6HPLaY9V39ovHRGVC8UEPJJ867ciDyr10kXDIlZEG8SlyF8KJ0
Lqc1N3EljNpGy8tFQRaNRZ+2LvqLoD+xH42SA9TLIwN+HstrWQaKPaeOCuyRpefd
Y2TlP8eLAgMBAAECggEAD4nQRKT7aKI00EGcgZFUcyrWTap9HxcoxHyjQa/hR7s9
hnDaKHP+l1Vee+XIZGLWZKgwLtFWh3EbunS3/jQ+rAihZhM1CDrkyPxdfU4zjaoC
nro7ngW9u17EAg+DT04IMd548VLrHeEMTIlf9+990AxcuRWfzwpFLwOQh3vlS9rw
qjZobvQ3BEo9Kr/iB6UUXC1E/XxMVGA3k3Q6p7vMeXYRfACp3+IwdwUBiVuowPul
hGG+J9LSBet6fkRhkwo0DrqSdjqQ4eu4pJ2N2TP3lW+hBFvFqGp6u6OSZMFMw8x/
vlf/hXgOpB6RAUppeBH+W40l8pECiXS1hnnQgRYhAQKBgQDm+JBbA+UEkojNRGex
ibOzd/2F4TxXdhQSrswkeCiQSHC4Ruh6olmhwrmLhAiHZHOpwL/FC3udMAZmh6/d
rx1Q3umQhMvI3FATcD7qlqPO6ium46t+60PB/AjOyUSxv4ARdJ0uh4ArAWPTy5XR
WLvnzNCQL178x+k4Gb9GLBtAgQKBgQDdRJD5RakcU2Jfvqz96e6eSsZfK9IaYhZA
fSq+xmt7iU+0NDS1iD1zBqPHt4XvIoB9RsfS0xp13HJIKBsokIIGNz3BsBcwBLwu
13YplgEM6FxpCXQ1dQh21q4VtuFGYitYTOIIckU53SiSOFxfk0SeybJF6CJFSDGr
8NeDABMCCwKBgCFUQvhvQm/7eTQtp8ztsvm12eakzuFMD692e8zTbf8MBQACc2+m
18pI4B9qyRRIgYxAXSvg8VCIapQHBnC14UQXNpr9Hq74Y7G6Y8nUPQURs4Tcm5Wv
+1IVvWuhjYEcwi1Cp5/cO7l49N/OI+tWo57aZko4G7vcWSIYTQqiOLiBAoGADYWU
KneUVxPNbjZz0eyK1YeSSdyesVgPLg+4HgJ4LQt+IHAUTIev4ailN55ChBOisIUz
zvFxq4Q2Q6yXxEnYeFLF5mFBeYDAk0g9g1sUY1qL0yttu5qUUtbZup/7clareXDx
WzzIeDnIse7ZzklspxuCVn1SItO/nVdRhELr5nMCgYEAiFtmtr/Cipq0G1+P4szD
VFNKYkPRB73NxEaVkp03xPeRgoUDL69jKg8mktq7y2udPm/revDjkSb10hSH+Kuo
61DWBd4TMdCm6pCN3u69yX1ZGUX5jZ9HF+8nCqH02cMpRcWc8w7q6uZ42BQXYuDl
wvEmUIjkhjf//lVML8+konw=
-----END RSA PRIVATE KEY-----
eol

  jws_public_key <<eol
-----BEGIN RSA PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAx6JxcaJa6w2SngHyAcxo
0FZk5ktRocOrRJMiF760wFb8UgXzuD3IDw3KxAp0Cf+jOv99d0TFxd27ORWNa8ME
ewWKzOQAX40GKrdN0oQIbK52LOjH9GzKm4B+6YrvINbFoOFgf3dQlsSJymJ9obkf
2FyVBn3PwRIHMN5nCOd/gsEAkf+vy4UX8KvdHW5bao5LmctuWSc6OMBHaWHwvh/T
RcJg110ehzy2mPVd/aLx0RlQvFBDySfOu3Ig8q9dJFwyJWRBvEpchfCidC6nNTdx
JYzaRsvLRUEWjUWfti76i6A/sR+NkgPUyyMDfh7La1kGij2njgrskaXn3WNk5T/H
iwIDAQAB
-----END RSA PUBLIC KEY-----
eol

  resource_owner_from_access_token do |access_token|
    # Example implementation:
    # User.find_by(id: access_token.resource_owner_id)
    User.where(id: access_token.resource_owner_id).first
  end

  issuer 'issuer string'

  subject do |resource_owner|
    # Example implementation:
    # resource_owner.key
  end

  # Expiration time on or after which the ID Token MUST NOT be accepted for processing. (default 120 seconds).
  # expiration 600

  claims do
    # claim :_foo_ do |resource_owner|
    #   resource_owner.foo
    # end
    #
    # claim :_bar_ do |resource_owner|
    #   resource_owner.bar
    # end
  end

end