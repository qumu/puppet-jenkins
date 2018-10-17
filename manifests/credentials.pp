# Copyright 2014 RetailMeNot, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Type jenkins::credentials
#
# Jenkins credentials (via the CloudBees Credentials plugin
#
define jenkins::credentials (
  $username = $title,
  String $password,
  String $description               = 'Managed by Puppet',
  String $private_key_or_path       = '',
  Enum['present', 'absent'] $ensure = 'present',
  String $uuid                      = '',
){

  include ::jenkins
  include ::jenkins::cli_helper

  Class['jenkins::cli_helper']
    -> Jenkins::Credentials[$title]
      -> Anchor['jenkins::end']

  if($uuid == '') {
    $validator = "\$HELPER_CMD credential_info ${uuid} ${username} | grep ${username}"
  }  
  else {
   $validator = "\$HELPER_CMD credential_info ${uuid} ${username} | grep ${uuid}"
  }
   
  case $ensure {
    'present': {
      validate_string($password)
      validate_string($description)
      validate_string($private_key_or_path)
      validate_string($uuid)
      jenkins::cli::exec { "create-jenkins-credentials-${title}":
        command => [
          'create_or_update_credentials',
          $username,
          "'${password}'",
          "'${uuid}'",
          "'${description}'",
          "'${private_key_or_path}'",
        ],
        #unless  => "\$HELPER_CMD credential_info ${uuid} ${title} | grep ${uuid}",
        unless  => "for i in \$(seq 1 ${::jenkins::cli_tries}); do \$HELPER_CMD credential_info ${title} && break || sleep ${::jenkins::cli_try_sleep}; done | grep ${title}", # lint:ignore:140chars
      }
    }
    'absent': {
      # XXX not idempotent
      jenkins::cli::exec { "delete-jenkins-credentials-${username}-${uuid}":
        command => [
          'delete_credentials',
          $username,
        ],
      }
    }
    default: {
      fail "ensure must be 'present' or 'absent' but '${ensure}' was given"
    }
  }
}
