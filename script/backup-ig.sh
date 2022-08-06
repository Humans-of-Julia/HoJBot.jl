#!/bin/sh
# Backup investment game data files
tar cf - data/ig | gzip -c > backup_ig_$$.tgz
