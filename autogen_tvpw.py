
# This will be ran as a cron job on raspberry pi
#  0 0 1 * * /usr/bin/python3 /u01/prd/python/autogen_tvow.py
import os
import argparse
import subprocess
import time
from datetime import datetime
from socket import gethostname
from pycrypt.encryption import Encryption
from pycrypt.PasswdGenerator import PasswordGenerator


if __name__ == '__main__':

    pw_exclude = ["'", '\\', '/', '"', '^', '&', '*', '(', ')',
                  '[', ']', '{', '}', '=', '+', '~', '`', '<',
                  '>', '?', ';', ':', '|', ',']

    enc = Encryption()
    pw_gen = PasswordGenerator()
    #Generate a new password and encrypt it with the email_pub public key so that it can be
    # emailed out.
    pw_gen.generate(size=12,
                    excluded_chars=pw_exclude,
                    encrypt=True,
                    public_key='/u01/prd/rsa/email_pub',
                    output_file='/u01/prd/tmp/newpw')

    #Lets unencrypt email username and password
    enc.decrypt(encrypted_data='/u01/prd/rsa/enc_secret',
                private_key_file='/u01/prd/rsa/key')
    secret = enc.get_decrypted_message()

    enc.decrypt(private_key_file='/u01/prd/rsa/local_key',
                encrypted_data='/u01/prd/rsa/enc_tvacctusrnme',
                secret_code=secret)
    to_addr = enc.get_decrypted_message()
    enc.decrypt(private_key_file='/u01/prd/rsa/local_key',
                encrypted_data='/u01/prd/rsa/enc_mailrelayuser',
                secret_code=secret)
    mailrelay_usr = enc.get_decrypted_message()
    enc.decrypt(private_key_file='/u01/prd/rsa/local_key',
                encrypted_data='/u01/prd/rsa/enc_mailrelaypsswd',
                secret_code=secret)
    mailrelay_passwd = enc.get_decrypted_message()
    mutt_config = "{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n".format(
        "set ssl_starttls = yes",
        "set ssl_force_tls = yes",
        "set smtp_url = 'smtp://{}@smtp.gmail.com:587/'".format(mailrelay_usr),
        "set smtp_pass = '{}'".format(mailrelay_passwd),
        "set imap_user = '{}'".format(mailrelay_usr),
        "set imap_pass = '{}'".format(mailrelay_passwd),
        "set from = '{}'".format(mailrelay_usr),
        "set realname = 'TeamViewer Autogen'",
        "set folder = imaps://imap.gmail.com:993/",
        "set spoolfile = '+INBOX'",
        "set postponed = '+[Gmail]/Drafts'",
        "set header_cache = '/u01/prd/tmp/.mutt/cache/headers'",
        "set message_cachedir = '/u01/prd/tmp/.mutt/cache/bodies'",
        "set certificate_file = '/u01/prd/tmp/.mutt/certificates'",
        "set move = no",
        "set imap_keepalive = 32000",
        "set mail_check = 32000",
    )
    with open('/u01/prd/tmp/muttrc', 'w') as f:
        f.write(mutt_config)
        f.close()
    subprocess.Popen("sudo teamviewer info > /u01/prd/tmp/tvinfo", shell=True,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    subject = "[TeamViewer-Autogen-Passwd]{}-{}".format(gethostname(), datetime.now().ctime())
    cli_args = 'echo "" | mutt -F /u01/prd/tmp/muttrc -s "{}" -i /u01/prd/tmp/tvinfo -a ' \
               '/u01/prd/tmp/newpw -- "{}"'.format(subject, to_addr)
    subprocess.Popen(cli_args, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    subprocess.Popen("sudo teamviewer passwd {}".format(pw_gen.get_decrypted()), shell=True,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    enc = None
    pw_gen = None

    # give the email time to send before clearing out the config file
    time.sleep(5)

    # clear the file that is holding passwords
    with open('/u01/prd/tmp/muttrc', 'w') as f:
        f.write('')
