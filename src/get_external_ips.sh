#!/usr/bin/env bash

# https://elrey.casa/bash/scripting/harden
set -${-//[sc]/}eu${DEBUG+xv}o pipefail

function build_aws_cmd(){
  if [[ -n "${aws_profile}" ]] ; then
    aws_cmd+=(
      '--profile' "${aws_profile}"
    )
  fi
}

function select_cluster(){
  # https://github.com/elreydetoda/packer-kali_linux/blob/master/prov_vagrant/prov.sh#L114-L154
  mapfile -t clusters < <("${aws_cmd[@]}" ecs list-clusters | jq -r '.clusterArns[]')

  until [ -n "${selected_cluster}" ]; do
    PS3=$'\nWhich cluster do you want? '
    printf '\n\n%s\n\n' "Select an cluster to use:" >&2

    select cluster in "${clusters[@]}"; do
      if [[ -n "${cluster}" ]]; then
        printf 'You chose number %s, setting cluster to %s\n\n' "${REPLY}" "${cluster}"
        selected_cluster="${cluster}"
        break
      else
        echo "Invalid selection, please try again."
      fi

    done
  done
  unset PS3
}

function get_tasks(){
  # jq at the end
  mapfile -t task_arr < <(
    "${aws_cmd[@]}" ecs list-tasks --query "taskArns[]" --cluster "${cluster_name}" |
    # this is to strip off the extra brackets from the aws command
    jq -r '.[]'
  )
}

function get_enis(){
  mapfile -t eni_arr < <(
    "${aws_cmd[@]}" ecs describe-tasks --query 'tasks[].attachments[].details[]' \
      --cluster "${cluster_name}" \
      --tasks "${task_arr[@]}" |
      # used to specifically get the all the network interface IDs, because builtin query was PIA
        jq -r '.[] | select(.name=="networkInterfaceId").value'
  )
}

function get_external_ips(){
  mapfile -t external_ips < <(
    "${aws_cmd[@]}" ec2 describe-network-interfaces \
      --query 'NetworkInterfaces[].Association.PublicIp' \
      --network-interface-ids "${eni_arr[@]}" |
        jq -r '.[]'
  )
}

function check_args(){
  if [[ $# -ne 1 ]] ; then
    echo "you didn't only provide 1 argument, are you sure you want to proceed?"
    echo "the 1 argument is used for the profile you'd like to use for AWS commands"
    echo "if you don't want to proceed, then please hit: Ctrl+c"
    read -r
  fi
}

function main(){
  aws_profile="${1:-}"
  aws_cmd=( 'aws' )
  task_arr=()
  eni_arr=()
  external_ips=()
  selected_cluster=''

  check_args "${@}"

  build_aws_cmd
  select_cluster

  cluster_name="${selected_cluster##*/}"

  get_tasks
  get_enis
  get_external_ips
  printf '%s\n' "${external_ips[@]}"
}

# https://elrey.casa/bash/scripting/main
if [[ "${0}" = "${BASH_SOURCE[0]:-bash}" ]] ; then
  main "${@}"
fi
