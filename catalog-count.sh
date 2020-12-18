#/bin/bash

# =====================================================================================================================
# Arguments and their defaults
MESH_NAME=${1:-UNSET}
KEYPATH=${2:-UNSET}
CERTPATH=${3:-UNSET}

# =====================================================================================================================
# FUNCTIONS

showhelp() {
    echo "Usage: ./catalog-count.sh <MESH_NAME> <KEY_PATH> <CERT_PATH>"
    echo "   MESH_NAME   The fully qualified domain name for the mesh to analyze."
    echo "               e.g.   mesh.greymatter.io"
    echo "   KEY_PATH    The absolute path to your x509 Private Key file required to access the mesh"
    echo "   CERT_PATH   The absolute path to your x509 Public Certificate file required to access the mesh"
    exit 1
}

fieldsforcluster() {
    displayName=$(echo ${clusters} | jq -r '.[] | select (.clusterName=="'${linecluster}'").name')
    version=$(echo ${clusters} | jq -r '.[] | select (.clusterName=="'${linecluster}'").version')
    owner=$(echo ${clusters} | jq -r '.[] | select (.clusterName=="'${linecluster}'").owner')
    capability=$(echo ${clusters} | jq -r '.[] | select (.clusterName=="'${linecluster}'").capability')
    minInstances=$(echo ${clusters} | jq -r '.[] | select (.clusterName=="'${linecluster}'").minInstances')
    maxInstances=$(echo ${clusters} | jq -r '.[] | select (.clusterName=="'${linecluster}'").maxInstances')
}

jsonforcluster() {
    fieldsforcluster
    echo "  - ${linecluster}"
    echo '      "'${linecluster}'":' >> ${JSON_FILE}
    echo '      {' >> ${JSON_FILE}
    echo '         "name":"'${displayName}'",' >> ${JSON_FILE}
    echo '         "version":"'${version}'",' >> ${JSON_FILE}
    echo '         "owner":"'${owner}'",' >> ${JSON_FILE}
    echo '         "capability":"'${capability}'",' >> ${JSON_FILE}
    echo '         "minInstances":"'${minInstances}'",' >> ${JSON_FILE}
    echo '         "maxInstances":"'${maxInstances}'"' >> ${JSON_FILE}
    echo '      }' >> ${JSON_FILE}
}

tsvforcluster() {
    fieldsforcluster
    printf '"%s"\t"%s"\t"%s"\t"%s"\t"%s"\t"%s"\t"%s"\t"%s"\n' "${linecluster}" "${licensetype}" "${displayName}" "${version}" "${owner}" "${capability}" "${minInstances}" "${maxInstances}" >> ${CSV_FILE}
}
csvforcluster() {
    fieldsforcluster
    printf '"%s","%s","%s","%s","%s","%s","%s","%s"\n' "${linecluster}" "${licensetype}" "${displayName}" "${version}" "${owner}" "${capability}" "${minInstances}" "${maxInstances}" >> ${CSV_FILE}
}

# =====================================================================================================================
# Check if any arguments are not set
if [[ $MESH_NAME == "UNSET" ]]; then
    showhelp
fi
if [[ $MESH_NAME == "--help" ]]; then
    showhelp
fi
if [[ $MESH_NAME == "?" ]]; then
    showhelp
fi
if [[ $KEYPATH == "UNSET" ]]; then
    KEYPATH=""
else
    KEYPATH="--key ${KEYPATH}"
fi
if [[ $CERTPATH == "UNSET" ]]; then
    CERTPATH=""
else
    CERTPATH="--cert ${CERTPATH}"
fi

echo "Processing ${MESH_NAME}"
if [[ $KEYPATH == "" ]]; then
    echo "As anonymous"
else
    echo "Using Identity"
    echo "  ${CERTPATH}"
    echo "  ${KEYPATH}"
fi

dateofreport=$(date '+%Y-%m-%d')

# # CATALOG_URL represents the endpoint of the catalog service to get the clusters for a mesh
CATALOG_URL="https://${MESH_NAME}/services/catalog/latest/clusters"

# JSON_FILE and CSV_FILE are file names to use for output
JSON_FILE="${MESH_NAME}-license-counts.${dateofreport}.json"
CSV_FILE="${MESH_NAME}-license-counts.${dateofreport}.csv"

# =====================================================================================================================
# Fetch data
clusters=$(curl -s -S -k ${KEYPATH} ${CERTPATH} ${CATALOG_URL})
# Clusters that are customer specific using data
customerdata=$(echo ${clusters} | jq -r '.[] | select (.owner!="Decipher" and .capability=="Data").clusterName')
# Clusters that are customer specific microservices
customermicroservices=$(echo ${clusters} | jq -r '.[] | select (.owner!="Decipher" and .capability!="Data").clusterName')
# Clusters that are part of Decipher (make up Sense and Fabric)
decipherclusternames=$(echo ${clusters} | jq -r '.[] | select (.owner=="Decipher").clusterName')


if [[ $clusters == "" ]]; then
    echo "Unable to gather required cluster information for reporting"
    exit 1
fi
if [[ $clusters == *"Jwt verification fails"* ]]; then
    echo "Unable to gather required cluster information for reporting"
    echo ${clusters}
    exit 1
fi

# =====================================================================================================================
# Open CSV Document
#printf "clusterName\tlicense\tname\tversion\towner\tcapability\tminInstances\tmaxInstances\n" > ${CSV_FILE}
printf '"clusterName","license","name","version","owner","capability","minInstances","maxInstances"\n' > ${CSV_FILE}
# =====================================================================================================================
# Open JSON Document
echo "{" > ${JSON_FILE}
# =====================================================================================================================
# FABRIC
echo 'Processing Fabric'
licensetype="Fabric"
echo "   \"fabric\": {" >> ${JSON_FILE}
fabriccount=0
while read -r linecluster
do
    isfabric=0
    if [[ $linecluster == "control-api" ]]; then
        isfabric=1
    fi
    if [[ $linecluster == "edge" ]]; then
        isfabric=1
    fi
    if [[ $linecluster == "jwt-security" ]]; then
        isfabric=1
    fi
    if [[ isfabric -gt 0 ]]; then
        if [[ fabriccount -gt 0 ]]; then
            echo "      ," >> ${JSON_FILE}
        fi
        jsonforcluster
        csvforcluster
        fabriccount=1
    fi    
done < <(printf '%s\n' "$decipherclusternames")
echo "   }," >> ${JSON_FILE}


# =====================================================================================================================
# SENSE
echo 'Processing Sense'
licensetype="Sense"
echo "   \"sense\": {" >> ${JSON_FILE}
sensecount=0
while read -r linecluster
do
    issense=0
    if [[ $linecluster == "catalog" ]]; then
        issense=1
    fi
    if [[ $linecluster == "dashboard" ]]; then
        issense=1
    fi
    if [[ $linecluster == "slo" ]]; then
        issense=1
    fi
    if [[ issense -gt 0 ]]; then
        if [[ sensecount -gt 0 ]]; then
            echo "      ," >> ${JSON_FILE}
        fi
        jsonforcluster
        csvforcluster
        sensecount=1
    fi    
done < <(printf '%s\n' "$decipherclusternames")
echo "   }," >> ${JSON_FILE}

# =====================================================================================================================
# DATA
echo 'Processing Data Nodes'
licensetype="Data"
echo "   \"data\": {" >> ${JSON_FILE}
datacount=0
while read -r linecluster
do
    if [[ datacount -gt 0 ]]; then
        echo "      ," >> ${JSON_FILE}
    fi
    jsonforcluster
    csvforcluster
    datacount=$((datacount+1))
done < <(printf '%s\n' "$customerdata")
echo "   }," >> ${JSON_FILE}

# =====================================================================================================================
# MICROSERVICES
echo 'Processing Microservices'
licensetype="Microservice"
echo "   \"microservices\": {" >> ${JSON_FILE}
microservicecount=0
while read -r linecluster
do
    if [[ microservicecount -gt 0 ]]; then
        echo "      ," >> ${JSON_FILE}
    fi
    jsonforcluster
    csvforcluster
    microservicecount=$((microservicecount+1))
done < <(printf '%s\n' "$customermicroservices")
echo "   }," >> ${JSON_FILE}

# =====================================================================================================================
# LICENSE SUMMARY
echo "   \"licensesummary\": {" >> ${JSON_FILE}
echo "      \"mesh\": \"${MESH_NAME}\"," >> ${JSON_FILE}
echo "      \"fabric\": ${fabriccount}," >> ${JSON_FILE}
echo "      \"sense\": ${sensecount}," >> ${JSON_FILE}
echo "      \"data\": ${datacount}," >> ${JSON_FILE}
echo "      \"microservices\": ${microservicecount}," >> ${JSON_FILE}
echo "      \"dateofreport\": \"${dateofreport}\"" >> ${JSON_FILE}
echo "   }" >> ${JSON_FILE}
echo "Totals     Fabric: ${fabriccount}   Sense: ${sensecount}   Data: ${datacount}   Microservices: ${microservicecount}"
echo "JSON Output File: ${JSON_FILE}"
echo "CSV Output File: ${CSV_FILE}"

# =====================================================================================================================
# Close JSON Document
echo "}" >> ${JSON_FILE}

