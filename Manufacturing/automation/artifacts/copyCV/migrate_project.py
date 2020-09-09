# Migrate a project

import os
import sys
import time

import argparse

from azure.cognitiveservices.vision.customvision.training import CustomVisionTrainingClient
from azure.cognitiveservices.vision.customvision.training.models import ImageUrlCreateBatch, ImageUrlCreateEntry, Region

def migrate_tags(src_trainer, dest_trainer, project_id, dest_project_id):
    tags =  src_trainer.get_tags(project_id)
    print ("Found:", len(tags), "tags")
    # Re-create all of the tags and store them for look-up
    created_tags = {}
    for tag in src_trainer.get_tags(project_id):
        print ("Creating tag:", tag.name, tag.id)
        created_tags[tag.id] = dest_trainer.create_tag(dest_project_id, tag.name, description=tag.description, type=tag.type).id
    return created_tags

def migrate_images(src_trainer, dest_trainer, project_id, dest_project_id, created_tags):
    # Migrate any tagged images that may exist and preserve their tags and regions.
    count = src_trainer.get_tagged_image_count(project_id)
    print ("Found:",count,"tagged images.")
    migrated = 0
    while(count > 0):
        count_to_migrate = min(count, 50)
        print ("Getting", count_to_migrate, "images")
        images = src_trainer.get_tagged_images(project_id, take=count_to_migrate, skip=migrated)
        images_to_upload = []
        for i in images:
            print ("Migrating", i.id, i.original_image_uri)
            if i.regions:
                regions = []
                for r in i.regions:
                    print ("Found region:", r.region_id, r.tag_id, r.left, r.top, r.width, r.height)
                    regions.append(Region(tag_id=created_tags[r.tag_id], left=r.left, top=r.top, width=r.width, height=r.height))
                entry = ImageUrlCreateEntry(url=i.original_image_uri, regions=regions)
            else:
                tag_ids = []
                for t in i.tags:
                    print ("Found tag:", t.tag_name, t.tag_id)
                    tag_ids.append(created_tags[t.tag_id])
                entry = ImageUrlCreateEntry(url=i.original_image_uri, tag_ids=tag_ids)

            images_to_upload.append(entry)

        upload_result = dest_trainer.create_images_from_urls(dest_project_id, images=images_to_upload)
        if not upload_result.is_batch_successful:
            print ("ERROR: Failed to upload image batch")
            for i in upload_result.images:
                print ("\tImage status:", i.id, i.status)
            exit(-1)

        migrated += count_to_migrate
        count -= count_to_migrate

    # Migrate any untagged images that may exist.
    count = src_trainer.get_untagged_image_count(project_id)
    print ("Found:", count, "untagged images.")
    migrated = 0
    while(count > 0):
        count_to_migrate = min(count, 50)
        print ("Getting", count_to_migrate, "images")
        images = src_trainer.get_untagged_images(project_id, take=count_to_migrate, skip=migrated)
        images_to_upload = []
        for i in images:
            print ("Migrating", i.id, i.original_image_uri)
            images_to_upload.append(ImageUrlCreateEntry(url=i.original_image_uri))

        upload_result = dest_trainer.create_images_from_urls(dest_project_id, images=images_to_upload)
        if not upload_result.is_batch_successful:
            print ("ERROR: Failed to upload image batch")
            for i in upload_result.images:
                print ("\tImage status:", i.id, i.status)
            exit(-1)
        migrated += count_to_migrate
        count -= count_to_migrate
    return images

def migrate_project(src_trainer, dest_trainer, project_id):
    # Get the original project
    src_project = src_trainer.get_project(project_id)
    print ("Source project:", src_project.name)
    print ("\tDescription:", src_project.description)
    print ("\tDomain:", src_project.settings.domain_id)
    if src_project.settings.classification_type:
        print ("\tClassificationType:", src_project.settings.classification_type)
    print("\tTarget Export Platforms:", src_project.settings.target_export_platforms)

    # Create the destination project
    return dest_trainer.create_project(src_project.name, description=src_project.description, domain_id=src_project.settings.domain_id, classification_type=src_project.settings.classification_type, target_export_platforms=src_project.settings.target_export_platforms)

if __name__ == "__main__":
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument("-p", "--project", action="store", type=str, help="Source project ID", dest="project_id", default=None)
    arg_parser.add_argument("-s", "--src", action="store", type=str, help="Source Training-Key", dest="source_training_key", default=None)
    arg_parser.add_argument("-se", "--src_endpoint", action="store", type=str, help="Source Endpoint", dest="source_endpoint", default="https://southcentralus.api.cognitive.microsoft.com")
    arg_parser.add_argument("-d", "--dest", action="store", type=str, help="Destination Training-Key", dest="destination_training_key", default=None)
    arg_parser.add_argument("-de", "--dest_endpoint", action="store", type=str, help="Destination Endpoint", dest="destination_endpoint", default="https://southcentralus.api.cognitive.microsoft.com")
    args = arg_parser.parse_args()

    if (not args.project_id or not args.source_training_key or not args.destination_training_key):
        arg_parser.print_help()
        exit(-1)

    print ("Collecting information for source project:", args.project_id)

    # Client for Source
    src_trainer = CustomVisionTrainingClient(args.source_training_key, endpoint=args.source_endpoint)

    # Client for Destination
    dest_trainer = CustomVisionTrainingClient(args.destination_training_key, endpoint=args.destination_endpoint)

    destination_project = migrate_project(src_trainer, dest_trainer, args.project_id)
    tags = migrate_tags(src_trainer, dest_trainer, args.project_id, destination_project.id)
    source_images = migrate_images(src_trainer, dest_trainer, args.project_id, destination_project.id, tags)