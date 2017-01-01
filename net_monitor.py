import subprocess as sub
import argparse, os, signal

parser = argparse.ArgumentParser()
parser.add_argument('--start', action='store_true')
parser.add_argument('--stop', action='store_true')
parser.add_argument('--pid', '-p', type=int)
args = parser.parse_args()

class NetworkTrace(object):
    tracePid = 2

    @staticmethod
    def start():
        p = sub.Popen(('sudo', 'tcpdump', '-w', 'test.txt'), stdout=sub.PIPE)
        NetworkTrace.tracePid = p.pid
        for row in iter(p.stdout.readline, b''):
            print row.rstrip()   # process here
            return NetworkTrace.tracePid

    @staticmethod
    def stop(pid):
        print pid
        os.kill(pid, signal.SIGTERM)


if __name__ == "__main__":
    if args.start:
        print "Starting Trace..."
        NetworkTrace.start()
    elif args.stop:
        print "Killing Trace..."
        NetworkTrace.stop(args.pid)


