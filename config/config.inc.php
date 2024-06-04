<?php

# Database management system to use
$DBMS = 'MySQL';

# Database variables

$_RAIL = array();
$_RAIL[ 'db_server' ]   = getenv('DB_SERVER') ?: '127.0.0.1';
$_RAIL[ 'db_database' ] = 'rdb';
$_RAIL[ 'db_user' ]     = 'root';
$_RAIL[ 'db_password' ] = '';
$_RAIL[ 'db_port']      = '3306';

# ReCAPTCHA settings
#   Used for the 'Insecure CAPTCHA' module
#   You'll need to generate your own keys at: https://www.google.com/recaptcha/admin
$_RAIL[ 'recaptcha_public_key' ]  = '';
$_RAIL[ 'recaptcha_private_key' ] = '';

# Default security level
#   Default value for the security level with each session.
#   The default is 'impossible'. You may wish to set this to either 'low', 'medium', 'high' or impossible'.
$_RAIL[ 'default_security_level' ] = 'impossible';

# Default locale
#   Default locale for the help page shown with each session.
#   The default is 'en'. You may wish to set this to either 'en' or 'zh'.
$_RAIL[ 'default_locale' ] = 'en';

# Disable authentication
#   Some tools don't like working with authentication and passing cookies around
#   so this setting lets you turn off authentication.
$_RAIL[ 'disable_authentication' ] = false;

define ('MYSQL', 'mysql');

# SQLi DB Backend
$_RAIL['SQLI_DB'] = MYSQL;

?>