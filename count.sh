#/bin/bash

projects=$(kubectl get project -o json | jq -r '.items[].metadata.name')

while read -r lineproject
do
echo "------------------------------------------------------------"
tfabric=0
tsense=0
tdata=0
tmicroservice=0
echo "Project/Namespace: $lineproject"
oc project $lineproject
cfabric=0
csense=0
cdata=0
cmicroservice=0
pods=$(kubectl get pods -o json | jq -r '.items[].metadata.name')
while read -r linepod
do
echo "  Pod: $linepod"
images=$(kubectl get pod $linepod -o json | jq -r '.spec.containers[].image')
cgmcontrol=0
cgmcontrolapi=0
cgmjwtsecurity=0
cprometheus=0
cgmcatalog=0
cgmdashboard=0
cgmslo=0
cgmdata=0
cinternal=0
cgmproxy=0
clen=0
cedge=0
while read -r lineimage
do
echo "    Image: $lineimage"
clen=$((clen+1))
if [[ $lineimage == *"/gm-control:"* ]]; then
  cgmcontrol=$((cgmcontrol+1)) 
fi
if [[ $lineimage == *"/gm-control-api:"* ]]; then
  cgmcontrolapi=$((cgmcontrolapi+1)) 
fi
if [[ $lineimage == *"/gm-jwt-security:"* ]]; then
  cgmjwtsecurity=$((cgmjwtsecurity+1)) 
fi
if [[ $lineimage == *"/prometheus:"* ]]; then
  cprometheus=$((cprometheus+1)) 
fi
if [[ $lineimage == *"/gm-catalog:"* ]]; then
  cgmcatalog=$((cgmcatalog+1)) 
fi
if [[ $lineimage == *"/gm-dashboard:"* ]]; then
  cgmdashboard=$((cgmdashboard+1)) 
fi
if [[ $lineimage == *"/gm-slo:"* ]]; then
  cgmslo=$((cgmslo+1)) 
fi
if [[ $lineimage == *"/gm-data:"* ]]; then
  cgmdata=$((cgmdata+1)) 
fi
if [[ $lineimage == *"/gm-proxy:"* ]]; then
  cgmproxy=$((cgmproxy+1)) 
fi
if [[ $linepod == *"internal-"* ]]; then
  cinternal=$((cinternal+1)) 
fi
if [[ $linepod == "edge-"* ]]; then
  cedge=$((cedge+1)) 
fi
done < <(printf '%s\n' "$images")  
if [[ cgmcontrol -gt 0 ]]; then
echo "    Type: Fabric"
cfabric=$((cfabric+1))
elif [[ cgmcontrolapi -gt 0 ]]; then
echo "    Type: Fabric"
cfabric=$((cfabric+1))
elif [[ cgmjwtsecurity -gt 0 ]]; then
echo "    Type: Fabric"
cfabric=$((cfabric+1))
elif [[ cprometheus -gt 0 ]]; then
echo "    Type: Fabric"
cfabric=$((cfabric+1))
elif [[ cgmcatalog -gt 0 ]]; then
echo "    Type: Sense"
csense=$((csense+1))
elif [[ cgmdashboard -gt 0 ]]; then
echo "    Type: Sense"
csense=$((csense+1))
elif [[ cgmslo -gt 0 ]]; then
echo "    Type: Sense"
csense=$((csense+1))
elif [[ cgmdata -gt 0 ]]; then
  if [[ cinternal -gt 0 ]]; then 
    echo "    Type: Fabric"
    cfabric=$((cfabric+1))
  else
    echo "    Type: Data"
    cdata=$((cdata+1))
  fi
elif [[ cgmproxy -gt 0 ]]; then
  if [[ clen -gt 1 ]]; then
    echo "    Type: Microservice"
    cmicroservice=$((cmicroservice+1))
  elif [[ cedge -gt 0 ]]; then
    echo "    Type: Fabric"
    cfabric=$((cfabric+1))
  else
    echo "    Type: Microservice"
    cmicroservice=$((cmicroservice+1))
  fi
else
  echo "    Type: Standalone"
fi
done < <(printf '%s\n' "$pods")
echo "------------------------------------------------------------"
echo "Total for Project/Namespace: $lineproject"
echo "fabric: $cfabric   sense: $csense   data: $cdata   microservice: $cmicroservice"
tfabric=$((tfabric+cfabric))
tsense=$((tsense+csense))
tdata=$((tdata+cdata))
tmicroservice=$((tmicroservice+cmicroservice))
done < <(printf '%s\n' "$projects")
echo "------------------------------------------------------------"
echo "Totals"
echo "fabric: $tfabric   sense: $tsense   data: $tdata   microservice: $tmicroservice"