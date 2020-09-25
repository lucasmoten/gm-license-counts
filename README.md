# gm-license-count-k8s
Interrogates Kubernetes to determine Grey Matter licenses and microservices in use.

It will iterate all projects, and then all pods within them, examining the images in use.  Based upon the docker images and the name of the pod it will assess what type of license is in use.  At the end of each project, totals for each of fabric, sense, data, and microservice are listed.  At the conclusion, a total summary for all projects is presented.

This script is run from the command line and expects you to already be logged into openshift.

It depends on presence of jq tool for parsing.

Logic follows this flow for determination.

![A flowchart depicting how greymatter license usage is determined](/images/license-flow.png)

# To Run

After you are logged into openshift, execute the following
```
chmod +x count.sh
./count.sh
```

You can redirect output to a file to review later
```
./count.sh > counts
```

If you just want the totals, you can use grep to filter the results
```
cat counts | grep -A 1 Total
```
