Matar Puertos:

sudo fuser -v 1883/tcp
sudo fuser -k 1883/tcp
# o:
sudo kill -9 $(sudo lsof -t -iTCP:1883 -sTCP:LISTEN) 2>/dev/null


Verficiar:
sudo ss -ltnp | egrep ':1883|:9001' || echo "libre"