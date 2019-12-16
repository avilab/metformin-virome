from Bio import Entrez
import pandas as pd

# esearch -db bioproject -query "PRJEB99111" | elink -target biosample | efetch -format docsum | xtract -pattern DocumentSummary -block Attribute -element Attribute

Entrez.email = "tapa741@gmail.com"
handle = Entrez.esearch(db="bioproject", term= "PRJEB1786") #, efetch, ...
record = Entrez.read(handle)
handle.close()
idlist = record['IdList'][0]
handle = Entrez.elink(db="biosample", dbfrom="bioproject", id=idlist, linkname='bioproject_biosample_all')
record = Entrez.read(handle)
handle.close()
print(record)
links = record[0]['LinkSetDb'][0]['Link']
links = [list(i.values())[0] for i in links]
handle = Entrez.efetch(db="biosample", id=links, rettype='docsum') #, efetch, ...
record = Entrez.read(handle)
handle.close()
records = record['DocumentSummarySet']['DocumentSummary']
ids = []
for record in records:
    reclist = [i.split(': ') for i in record['Identifiers'].split('; ')]
    recdic = {i[0]: i[1] for i in reclist}
    recdf = pd.DataFrame(recdic, index=[list(recdic.values())[0]])
    ids.append(recdf)

ids_concatenated = pd.concat(ids)
ids_concatenated.to_csv("output/PRJEB1786_metadata.csv", index = False)
