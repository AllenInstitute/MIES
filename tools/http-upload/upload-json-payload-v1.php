<?php

// Installation instructions
//
// - Create folder on website and put this script there
// - Create an `uploads` folder and place the `.htaccess` file there
// - Try it out with curl
//   curl -X PUT -d '{"payload" : [{"name" : "abcd.txt", "contents" : "abcd"}]}' https://ai.customers.byte-physics.de/upload-json-payload-v1.php
//
// Example JSON file
//
// {
//   "computer" : "abcd",
//   "user" : "schorsch",
//   "timestamp" : "2020-02-20T08:50:23Z",
//   "payload" :
//    [
//      {
//        "name" : "crash.dump",
//        "encoding" : "base64",
//        "contents" : "base 64 encoded file contents"
//      },
//      {
//        "name" : "msg.txt",
//        "contents" : "plain text file contents"
//      }
//    ]
// }

/// @brief Return the value of `key` from `array` if it exists or `default_value` otherwise
function get_array_value($array, $key, $default_value = null)
{
  return (is_array($array) && array_key_exists($key, $array)) ? $array[$key] : $default_value;
}

/// @brief Convert `str` to safe filename on *nix OSes
function sanitize_filename($str)
{
  return preg_replace("/[^a-zA-Z0-9.: ]+/", "-", $str);
}

/// @brief Create a unique folder named `basefolder_XXX` and return its name
function create_unique_folder($basefolder)
{
  $folder = $basefolder;

  $count=0;
  while(!mkdir($folder, 0700, true))
  {
    $folder = $basefolder . "_" . $count++;
  }

  return $folder;
}

/// @brief Extract the file contents from the elements of the `payload` array
function decode_contents($elem)
{
    $encoding = get_array_value($elem, "encoding", "plain");

    if($encoding == "plain")
    {
      return $elem["contents"];
    }
    elseif($encoding == "base64")
    {
      $contents = base64_decode($elem["contents"], True);

      if($contents == False) # not base64 encoded
      {
        die("Contents could not be base64 decoded");
      }

      return $contents;
    }

    die("Invalid encoding value.");
}

// get the HTTP method, path and body of the request
$method = $_SERVER["REQUEST_METHOD"];

if($method != "PUT")
{
  die("Unsupported HTTP method");
}

$received_data = file_get_contents("php://input");

if($received_data == False)
{
  die("Missing data on HTTP PUT method.");
}

$input = json_decode($received_data, true);

if(!array_key_exists("payload", $input))
{
  die("Missing payload");
}

$computer = get_array_value($input, "computer", "unknown");
$user = get_array_value($input, "user", "unknown");
$timestamp = get_array_value($input, "timestamp", "unknown");

$folder = create_unique_folder("uploads/" . sanitize_filename($computer . "-" . $user . "-" . $timestamp));

foreach($input["payload"] as $elem)
{
  if(array_key_exists("name", $elem) and array_key_exists("contents", $elem))
  {
    $filename = tempnam($folder, sanitize_filename($elem["name"]) . ".");
    $contents = decode_contents($elem);

    $ret = file_put_contents($filename, $contents);
    if($ret == 0 || $ret == FALSE)
    {
      die("Problem writing file " . $filename);
    }
  }
}
