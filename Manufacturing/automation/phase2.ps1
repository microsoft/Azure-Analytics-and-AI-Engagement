#Custom Vision 
pip install -r ./artifacts/copyCV/requirements.txt
$key=az cognitiveservices account keys list --name $customVisionName -g $rgName|ConvertFrom-json
$key=$key.key1

$destinationKey=$key
$sourceKey="7f743d4b8d6d459fb2bb0e8648dfa38e"  #todo: find a way to get this securely
$sourceProjectId="b2e4f4ce-d9f1-4fb7-aa0c-2f50fdc14d1b"
$destinationregion= "https://$($location).api.cognitive.microsoft.com"
$sourceregion= "https://westus2.api.cognitive.microsoft.com"
python ./artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion
$url = "https://$($location).api.cognitive.microsoft.com/customvision/v3.2/training/projects"
$projects = Invoke-RestMethod -Uri $url -Method GET  -ContentType "application/json" -Headers @{ "Training-key"="$($destinationKey)" };
foreach($project in $projects)
{
	$projectId=$project.id
	$projectName=$project.name
	$url = "https://$($location).api.cognitive.microsoft.com/customvision/v3.2/training/projects/$($project.id)/tags"
	$tags = Invoke-RestMethod -Uri $url -Method GET  -ContentType "application/json" -Headers @{ "Training-key"="$($destinationKey)" };
	$tagList = New-Object System.Collections.ArrayList
	foreach(tag in tags)
	{
		$tagList.Add(tag.id)
	}
	$body = "{
      `"selectedTags`": []
		}"
	$body=	$body |ConvertFrom-Json
	$body.selectedTags=$tagList	
	$body=	$body |ConvertTo-Json
	$url = "https://$($location).api.cognitive.microsoft.com/customvision/v3.2/training/projects/$($projectId)/train"
	$Result = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{"Training-key"="$($destinationKey)"}
	
	$url="https://$($location).api.cognitive.microsoft.com/customvision/v3.3/Training/projects/$($projectId)/iterations"
	$iterations=Invoke-RestMethod -Uri $url -Method GET  -ContentType "application/json" -Headers @{ "Training-key"="$($destinationKey)" };
	$iterationId=$iterations[0].id
	$url="https://$($location).api.cognitive.microsoft.com/customvision/v3.3/Training/projects/$($projectId)/iterations/$($iterationId)/publish?publishName=$($projectName)&predictionId=$predictionId"  #TODO Prediction ID
	$body = "{}"
	$Result = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{"Training-key"="$($destinationKey)"}
	
}
