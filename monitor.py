import argparse, time, subprocess, collections, operator
import pdb
import scapy.all as sc

parser = argparse.ArgumentParser()
parser.add_argument('--timeout', '-t', type=int)
parser.add_argument('--analyze', action='store_true')
args = parser.parse_args()

class NetworkTrace(object):

    @staticmethod
    def sniff():
        print "Sniffing..."
        if args.timeout:
            pkts = sc.sniff(filter="tcp", timeout=args.timeout)
        else:
            print "Need timeout"
            return

        curr_time = int(time.time())
        sc.wrpcap("sniff_{0}.cap".format(curr_time), pkts)

        nflxIPs = []
        if args.analyze:
            print "Analyzing..."
            srcIPs = collections.defaultdict(int)
            for pkt in pkts:
                srcIPs[pkt[sc.IP].src] += 1
            sortedIPs = sorted(srcIPs.items(), key=operator.itemgetter(1), reverse=True)
            for (ip, _) in sortedIPs[:3]:
                print "checking out " + ip
                p1 = subprocess.Popen(['nslookup', ip], stdout=subprocess.PIPE)
                p2 = subprocess.Popen(['grep', '-e', 'google', '-e', 'youtube'], stdin=p1.stdout, stdout=subprocess.PIPE)
                o = p2.communicate()
                if len(o[0]) > 0:
                    nflxIPs.append(ip)
            nflxPkts = [pkt for pkt in pkts if pkt[sc.IP].src in nflxIPs]
            sc.wrpcap("analyze_{0}.cap".format(curr_time), nflxPkts)

if __name__ == "__main__":
        NetworkTrace.sniff()
