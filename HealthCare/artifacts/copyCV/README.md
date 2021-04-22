---
page_type: sample
languages:
- python
products:
- azure
description: "Sample script to copy a Custom Vision project from one Subscription/Region to another."
urlFragment: custom-vision-move-project
---

# Move Custom Vision Project

Sample script to copy a Custom Vision project from one Subscription/Region to another.

## Getting Started

### Prerequisites

* [Python](https://www.python.org/downloads/)
* [Pip](https://pip.pypa.io/en/stable/installing/)

### Installation

To run the script you first install the requirements
```
pip install -r requirements.txt
```

### Quickstart

To run you need this information:

From the settings page of the source Subscription (_where you want to copy **from**_)
* Source Project Id
* Source Training Key
* Source Endpoint, _if not south central us_

From the settings page of the destination Subscription (_where you want to copy **to**_)
* Destination Training Key
* Destination Endpoint, _if not south central us_

Then run the python script with the necessary information:
```Python
python migrate_project.py -p "<project id>" -s "<source training key>" -d "<destination training key>"
```

This script will recreate a project with the destination training-key and download/upload all of the tags, regions, and images. It will leave you with a new project in your new subscription with no trained iterations, from here you can train a new iteration.

The migration script assumes you are migrating projects in South Central US. If you need to migrate a project from one region to another then you can specify the endpoints. 

For example, to migrate from South Central US to North Europe:

```Python
python migrate_project.py -p "<project id>" -s "<source training key>" -se "https://southcentralus.api.cognitive.microsoft.com" -d "<destination training key>" -de "https://northeurope.api.cognitive.microsoft.com"
```

## Resources

[Training SDK Documentation](https://southcentralus.dev.cognitive.microsoft.com/docs/services/Custom_Vision_Training_3.0/operations/5c771cdcbf6a2b18a0c3b7fa)
