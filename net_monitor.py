import subprocess as sub
import argparse, os, signal
import pdb

parser = argparse.ArgumentParser()
parser.add_argument('--start', action='store_true')
parser.add_argument('--stop', action='store_true')
parser.add_argument('--pid', '-p', type=int)
args = parser.parse_args()

class NetworkTrace(object):
    tracePid = 2

    @staticmethod
    def start():
        p = sub.Popen(('sudo', 'tcpdump', '-w', 'test.cap', '&'))
        NetworkTrace.tracePid = p.pid
        # pdb.set_trace()
        # p.stdout.readline()
        # return
        # for row in iter(p.stdout.readline, b''):
        #     print "HEY"
        #     print row.rstrip()   # process here
        #     print "HI"
        #     return NetworkTrace.tracePid

    @staticmethod
    def stop(pid):
        print pid
        os.kill(pid, signal.SIGTERM)


if __name__ == "__main__":
    if args.start:
        print "Starting Trace..."
        NetworkTrace.start()
        print NetworkTrace.tracePid
    elif args.stop:
        print "Killing Trace..."
        NetworkTrace.stop(args.pid)


