import os
import sys
import subprocess
import json
import hashlib

ImageExtensions = ["jpg", "png"]


dir = sys.argv[1]
if(len(dir) < 1):
    print("Expecting directory")
    sys.exit(-1)
dir = os.path.realpath(dir)
for file in os.listdir(dir):
    try:
        exif = json.loads(subprocess.run(["exiftool", "-j", file], capture_output=True).stdout)
        what = exif[0]['FileTypeExtension']
        sha256 = hashlib.sha256()
        ba = bytearray(65536)
        mv = memoryview(ba)
        with open(file, 'rb', buffering=0) as f:
            while n:= f.readinto(mv):
                sha256.update(mv[:n])
        hex = sha256.hexdigest()
        src = os.path.join(dir, file)
        dest = os.path.join(dir, "%s.%s" % (hex, what))
        print("rename %s to %s" % (src, dest))
        os.rename(src, dest)
    except:
        pass