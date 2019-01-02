# simple-kube-sync
An easy way to get the Heroku feel when building and deploying your Kubernetes apps

## What is it?

This project runs as a CronJob on Kubernetes and syncs an application from a git repository. It supports the following OS/Architectures:

| OS | Architecture |
|--|--|
| Linux | AMD64 |
| Linux | ARM32v7 |

This project attempts to be the simplest possible way to get this working. It was created to help with deploying software to a Raspberry Pi running Kubernetes. The lack of ARM support from other projects was the single driver for its creation.

If you're looking for something a little more feature rich or battle tested, then I'd suggest looking at:
* [gitkube](https://github.com/hasura/gitkube)
* [kube-applier](https://github.com/box/kube-applier/)

## How does it work?

The project is built as a multi-targetted container based of the **buildpack-deps** project. It has a single script called *entrypoint.sh* that does the following:

1. Clones the repo found in the environment variable *GIT_REPO* and switches directory into the root of the repo.
1. Looks for a file named *build.sh* and executes it if found.
1. Looks for a file named *apply.sh* and executes it if found. Otherwise, it runs *kubectl apply -f .*
1. Looks for a file named *tidy.sh* and executes it if found.

## How do you use it?

Get your git repo URL ready...

### Without RBAC

    sed "s|__GIT_REPO__|[my_url]|g" \
      https://raw.githubusercontent.com/ducas/simple-kube-sync/master/scripts/cronjob.yaml \
      > kubectl apply -f -

### With RBAC

    sed "s|__GIT_REPO__|[my_url]|g" \
      https://raw.githubusercontent.com/ducas/simple-kube-sync/master/scripts/cronjob_rbac.yaml \
      > kubectl apply -f -


The above commands deploy a CronJob that runs the application with your git repo URL.