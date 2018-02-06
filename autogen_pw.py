
# Used to generate a random 32 char passwd

import os
import argparse
import subprocess
import time
from datetime import datetime
from socket import gethostname
from pycrypt.encryption import Encryption
from pycrypt.PasswdGenerator import PasswordGenerator


if __name__ == '__main__':

    pw_exclude = ["'", '"', '\\', '/', '^', '&', '*', '(', ')',
                  '[', ']', '{', '}', '=', '+', '~', '`', '<',
                  '>', '?', ';', ':', '|', ',', '.', '!', '@',
                  '#', '$', '%']

    enc = Encryption()
    pw_gen = PasswordGenerator()
    pw_gen.generate(size=32,
                    excluded_chars=pw_exclude,
                    encrypt=False)

    print(pw_gen.get_decrypted())
