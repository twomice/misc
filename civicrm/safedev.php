<?php

civicrm_initialize();


// Change outbound mail setting to mail();
$mailing_backend = Civi::settings()->get('mailing_backend');
$mailing_backend['outBound_option'] = 3;
Civi::settings()->set('mailing_backend', $mailing_backend);
echo "Outbound mail has been set to mail().\n";

// Disable all non-dummy processors.
$result = civicrm_api3('PaymentProcessor', 'get', array(
  'sequential' => 1,
  'payment_processor_type_id' => array('!=' => "Dummy"),
));
foreach ($result['values'] as $value) {
  $params = array(
    'id' => $value['id'],
    'is_active' => 0,
  );
  civicrm_api3('PaymentProcessor', 'create', $params);
  echo "Disabled payment processor id#$id (${value['name']}).\n";

}