# gm-license-counts

Scripts for determining Grey Matter licenses and microservices in use.

- catalog-count : Leverages the Grey Matter Catalog service to identify licenses in use
- kubetcl-count : Interrogates Kubernetes to determine licenses in use.

__Dependencies__

These scripts depend on presence of jq tool for parsing.

## catalog-count.sh

Leverages the Grey Matter Catalog service to identify licenses in use

Specifying a target mesh and your x509 credentials, this script makes a curl command to retrieve the current cluster definitions in the catalog service.  From that it is able to determine the licenses in use and will generate JSON and CSV files summarizing what clusters are associated with each license type.

This script is run from the command line

Logic follows this flow for determination.

![A flowchart depicting how greymatter license usage is determined with catalog service](/images/license-flow-catalog.png)

### To Run

Ensure the script is executable
```sh
chmod +x catalog-count.sh
```

Run with no parameters to see usage arguments
```sh
./catalog-count.sh 
Usage: ./catalog-count.sh <MESH_NAME> <KEY_PATH> <CERT_PATH>
   MESH_NAME   The fully qualified domain name for the mesh to analyze.
               e.g.   mesh.greymatter.io
   KEY_PATH    The absolute path to your x509 Private Key file required to access the mesh
   CERT_PATH   The absolute path to your x509 Public Certificate file required to access the mesh
```

Run specifying a mesh and your PKI certificate files
```sh
./catalog-count.sh mesh.greymatter.io /path/to/mycertificate.key /path/to/mycertificate.pem
```

If successful, your output should look similar to the following
```
Processing mesh.greymatter.io
Processing Sense
Processing Data Nodes
Processing Microservices
Totals     Fabric: 1   Sense: 1   Data: 4   Microservices: 37
JSON Output File: mesh.greymatter.io-license-counts.2020-12-17.json
CSV Output File: mesh.greymatter.io-license-counts.2020-12-17.csv
```

The output JSON and CSV files are useful as inputs for reporting.

## kubectl-count.sh

Interrogates Kubernetes to determine Grey Matter licenses and microservices in use.

It will iterate all projects, and then all pods within them, examining the images in use.  Based upon the docker images and the name of the pod it will assess what type of license is in use.  At the end of each project, totals for each of fabric, sense, data, and microservice are listed.  At the conclusion, a total summary for all projects is presented.

This script is run from the command line and expects you to already be logged into openshift.

Logic follows this flow for determination.

![A flowchart depicting how greymatter license usage is determined with kubernetes](/images/license-flow-kubectl.png)

### To Run

After you are logged into openshift, execute the following
```
chmod +x kubectl-count.sh
./kubectl-count.sh
```

You can redirect output to a file to review later
```
./kubectl-count.sh > counts
```

If you just want the totals, you can use grep to filter the results
```
cat counts | grep -A 1 Total
```

