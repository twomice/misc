#!/usr/bin/php
<?php
/*
 * google-voice-dialer, modified
 *
 * google-voice-dialer:
 *      author: tylerhall
 *      url: http://github.com/tylerhall/google-voice-dialer/tree/master
 *      license: MIT Open Source License (http://www.opensource.org/licenses/mit-license.php)
 *
 * modified by: Allen Shaw (http://twomiceandastrawberry.com)
 * modifications:
 *      added function togglePhones
 *      added properties $status, $json
 *      added initialization of $json property
 */

define('GV_BASE_DIRECTORY', dirname(__FILE__));

require getenv('HOME') .'/.gv.conf';
require GV_BASE_DIRECTORY .'/simple_html_dom.php';
require GV_BASE_DIRECTORY . '/phpuri/phpuri.php';
require GV_BASE_DIRECTORY . '/json.php';

$gv = new GoogleVoice(USERNAME, PASSWORD);

$cmd = strtolower($argv[1]);
switch ($cmd) {
    case 'toggle':
        toggle($argv[2], $gv);
    break;

    case 'call':
        call($argv[2], $gv);
    break;

    case 'sms':
        sms($argv[2], $argv[3], $gv);
    break;

    default:
        printUsage();
    break;
}

$status = $gv->getStatus();
if ($status) {
  msgbox("ALERT: \n". $status);
}

function toggle($arg, $gv) {
    if (strtolower($arg) == 'list') {
        $cmd = 'getPhoneList';
        $phones = $gv->getPhoneList();
        if (is_array($phones)) {
            $msg = '';
            foreach ($phones as $phone => $id) {
                $msg .="$phone: $id\n";
            }
            msgbox($msg);
        } else {
            msgbox("No phones found. \n". $gv->getStatus());
        }
    } else {
        $cmd = 'togglePhones';
        $onId = (string)(int)$arg;
        if (!$onId) {
            printUsage();
            die();
        }
        $gv->togglePhones($arg);
        msgbox($gv->getStatus());
    }
}

function call($arg, $gv) {
    if ($arg) {
      $gv->call(HOMENUMBER, $arg);
      msgbox("Calling $arg: Ringing you at ". HOMENUMBER);
    } else {
      printUsage();
      die();
    }
}

function sms($number, $text, $gv) {
    if ($number && $text) {
        $gv->sms($number, $text);
        msgbox("Sending sms to $number: ". addslashes($text));
    } else {
      printUsage();
      die();
    }
}

function printUsage() {
    global $argv;
msgbox ("Improper syntax or usage.
Usage: {$argv[0]} cmd args
where cmd is one of the following commands, with required args:
    call (number)
        Place a call to (number) from configured HOMENUMBER

    sms (number) (text)
        Send an sms message (text) to (number)

    toggle (arg)
        Set one of your phones as the active forward. (arg) can be one of the following:
            N
                Enable the phone with the id number N
            list
                List phones with their id numbers
");
}


function msgbox($msg) {
    if ($msg) {
        if (getenv('DISPLAY')) {
            system ('xterm -e dialog --title "togglePhones" --clear --msgbox "'. $msg .'" 20 80');
        } else {
            if (defined('LOGFILE')) {
                $logfile = LOGFILE;
            } else {
                $logfile = '/tmp/gv.'. getenv('LOGNAME') .'.log';
            }
            if ((!file_exists($logfile) && !is_writable(dirname($logfile))) && !is_writable($logfile)) {
                $logfile = '/tmp/gv.'. uniqid() .'.log';
                if ((!file_exists($logfile) && !is_writable(dirname($logfile))) && !is_writable($logfile)) {
                    // giving up. can't find a logfile to write to.
                    echo "$logfile not writable\n$msg\n";
                    return;
                }
            }
            $fp = fopen($logfile, 'a');
            fwrite ($fp, date('r') .":\n". $msg ."\n\n");
            fclose($fp);
        }
    }
}

class GoogleVoice
{
    public $username;
    public $password;
    public $status;

    private $json;

    private $lastURL;

    public function __construct($username, $password)
    {
        $this->username = $username;
        $this->password = $password;
        $this->json = new Services_JSON();
    }

    // Login to Google Voice
    public function login()
    {
        $html = $this->curl('http://www.google.com/voice/m');

        $action = $this->match('!<form.*?action="(.*?)"!ms', $html, 1);

        $action = phpUri::parse($this->lastURL)->join($action);

        $post = "Email={$this->username}&Passwd={$this->password}";

        $dom = str_get_html($html);
        foreach($dom->find('input[type=hidden]') as $element) {
            $post .= '&'. $element->name .'='. urlencode($element->value);
        }

        $html = $this->curl($action, $this->lastURL, $post);

        $crumb = urlencode($this->match('!<input.*?name="_rnr_se".*?value="(.*?)"!ms', $html, 1));
        if (!$crumb) {
            return false;
        } else {
            return $html;
        }
    }

    // Connect $you to $them. Takes two 10 digit US phone numbers.
    public function call($you, $them)
    {
        $you = preg_replace('/[^0-9]/', '', $you);
        $them = preg_replace('/[^0-9]/', '', $them);

        $html = $this->login();
        if (!$html) {
            $this->addStatus('Login failed');
            return false;
        }

        $crumb = urlencode($this->match('!<input.*?name="_rnr_se".*?value="(.*?)"!ms', $html, 1));

        $post = "_rnr_se=$crumb&number=$them&call=Call";
        $html = $this->curl("https://www.google.com/voice/m/callsms", $this->lastURL, $post);

        $post = '';
        $dom = str_get_html($html);
        foreach($dom->find('input[type=hidden]') as $element) {
            $post .= '&'. $element->name .'='. urlencode($element->value);
        }

        $post .= "&phone=+1$you&Call=Call";

        $html = $this->curl("https://www.google.com/voice/m/sendcall", $this->lastURL, $post);
        
    }

    // Connect $you to $them. Takes two 10 digit US phone numbers.
    public function sms($number, $text)
    {
        $number = preg_replace('/[^0-9]/', '', $number);

        $html = $this->login();
        if (!$html) {
            $this->addStatus('Login failed');
            return false;
        }

        $crumb = urlencode($this->match('!<input.*?name="_rnr_se".*?value="(.*?)"!ms', $html, 1));

        $post = "_rnr_se=$crumb&id=&phoneNumber=$number&text=". urlencode($text);

        $html = $this->curl("https://www.google.com/voice/sms/send", $this->lastURL, $post);
    }

    // Turn on the given phone Id, turn off the other.
    public function togglePhones($onId)
    {
        $html = $this->login();
        if (!$html) {
            $this->addStatus('Login failed');
            return false;
        }

        $crumb = urlencode($this->match('!<input.*?name="_rnr_se".*?value="(.*?)"!ms', $html, 1));

        $html = $this->curl("https://www.google.com/voice/settings/tab/phones", $this->lastURL);
        $xml = my_xml2array($html, 'string');

        $jsonData = $this->json->decode($xml[0][0]['value']);
        $phones = (array)$jsonData->phones;
        $phoneIds = array_keys($phones);

        $post = "_rnr_se={$crumb}&enabled=1&phoneId={$onId}";
        $html = $this->curl("https://www.google.com/voice/settings/editDefaultForwarding/", $this->lastURL, $post);
        $response = $this->json->decode($html);
        if ($response->ok) {
            $this->addStatus("enabled phone $onId ({$jsonData->phones->$onId->name})");
        }

        foreach ($phoneIds as $id) {
            if ($id <> $onId) {
                $post = "_rnr_se={$crumb}&enabled=0&phoneId={$id}";
                $html = $this->curl("https://www.google.com/voice/settings/editDefaultForwarding/", $this->lastURL, $post);

                $response = $this->json->decode($html);
                if ($response->ok) {
                    $this->addStatus("disabled phone $id ({$jsonData->phones->$id->name})");
                }
            }
        }
    }

    // Turn on the given phone Id, turn off the other.
    public function getPhoneList()
    {
        $html = $this->login();
        if (!$html) {
            $this->addStatus('Login failed');
            return false;
        }

        $crumb = urlencode($this->match('!<input.*?name="_rnr_se".*?value="(.*?)"!ms', $html, 1));

        $html = $this->curl("https://www.google.com/voice/settings/tab/phones", $this->lastURL);
        $xml = my_xml2array($html, 'string');

        $jsonData = $this->json->decode($xml[0][0]['value']);
        $phones = (array)$jsonData->phones;
        foreach ($phones as $id=>$phone) {
            $return[$id] = $phone->name;
        }
        return $return;
    }

    private function curl($url, $referer = null, $post = null, $return_header = false)
    {
        static $tmpfile;

        if(!isset($tmpfile) || ($tmpfile == '')) $tmpfile = tempnam('/tmp', 'FOO');

        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_COOKIEFILE, $tmpfile);
        curl_setopt($ch, CURLOPT_COOKIEJAR, $tmpfile);
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
        curl_setopt($ch, CURLOPT_USERAGENT, "Mozilla/5.0 (iPhone; U; CPU iPhone OS 2_2_1 like Mac OS X; en-us) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5H11 Safari/525.20");
        if($referer) curl_setopt($ch, CURLOPT_REFERER, $referer);

        if(!is_null($post))
        {
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, $post);
        }

        if($return_header)
        {
            curl_setopt($ch, CURLOPT_HEADER, 1);
            $html        = curl_exec($ch);
            $header_size = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
            $this->lastURL = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
            $ret = substr($html, 0, $header_size);
        }
        else
        {
            $html = curl_exec($ch);
            $this->lastURL = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
            $ret = $html;
        }

        $errors = curl_error($ch);
        if (!empty($errors)) {
          $this->addStatus("CURL ERRORS: $errors");
        }

        return $ret;
    }

    private function match($regex, $str, $i = 0)
    {
        return preg_match($regex, $str, $match) == 1 ? $match[$i] : false;
    }

    private function addStatus($status) {
      $this->status[] = $status;
    }

    function getStatus() {
      return implode("\n", $this->status);
    }
}


/* xml-to-array converter, by vladimir_wof_nikolaich_dot_ru <http://www.php.net/manual/en/function.xml-parse.php#90733> */
function my_xml2array($xml, $xmltype = 'file')
{
    $xml_values = array();
    if ($xmltype == 'file') {
        $contents = file_get_contents($__url);
    } else {
        $contents = $xml;
    }
    $parser = xml_parser_create('');
    if(!$parser)
        return false;

    xml_parser_set_option($parser, XML_OPTION_TARGET_ENCODING, 'UTF-8');
    xml_parser_set_option($parser, XML_OPTION_CASE_FOLDING, 0);
    xml_parser_set_option($parser, XML_OPTION_SKIP_WHITE, 1);
    xml_parse_into_struct($parser, trim($contents), $xml_values);
    xml_parser_free($parser);
    if (!$xml_values)
        return array();

    $xml_array = array();
    $last_tag_ar =& $xml_array;
    $parents = array();
    $last_counter_in_tag = array(1=>0);
    foreach ($xml_values as $data)
    {
        switch($data['type'])
        {
            case 'open':
                $last_counter_in_tag[$data['level']+1] = 0;
                $new_tag = array('name' => $data['tag']);
                if(isset($data['attributes']))
                    $new_tag['attributes'] = $data['attributes'];
                if(isset($data['value']) && trim($data['value']))
                    $new_tag['value'] = trim($data['value']);
                $last_tag_ar[$last_counter_in_tag[$data['level']]] = $new_tag;
                $parents[$data['level']] =& $last_tag_ar;
                $last_tag_ar =& $last_tag_ar[$last_counter_in_tag[$data['level']]++];
                break;
            case 'complete':
                $new_tag = array('name' => $data['tag']);
                if(isset($data['attributes']))
                    $new_tag['attributes'] = $data['attributes'];
                if(isset($data['value']) && trim($data['value']))
                    $new_tag['value'] = trim($data['value']);

                $last_count = count($last_tag_ar)-1;
                $last_tag_ar[$last_counter_in_tag[$data['level']]++] = $new_tag;
                break;
            case 'close':
                $last_tag_ar =& $parents[$data['level']];
                break;
            default:
                break;
        };
    }
    return $xml_array;
}




