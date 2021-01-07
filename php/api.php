<head>
    <title>大液泡的随机图片api</title>
    <link rel="Shortcut Icon" href="https://resource.dayepao.com/photo/dayepao.ico" type="image/x-icon" />
    <style>

    img {
        height: auto;
        width: auto;
        max-width: 100%;
        margin: auto;
    }

    </style>
</head>
<?php
$o = "bing";
$imgs = scandir("/onedrive/resource/photo/$o/");
$num = array_rand($imgs);
$img = $imgs[$num];
print_r("<img src='https://resource.dayepao.com/photo/$o/$img'/>");
$url = 'https://'.$_SERVER['HTTP_HOST'].$_SERVER['PHP_SELF'].'?'.$_SERVER['QUERY_STRING'];
function getUrlKeyValue($url)
{
    $result = array();
    $mr = preg_match_all('/(\?|&)(.+?)=([^&?]*)/i', $url, $matchs);
    if ($mr !== false) {
        for ($i = 0; $i < $mr; $i++) {
            $result[$matchs[2][$i]] = $matchs[3][$i];
        }
    }
    return $result;
}
$value = getUrlKeyValue($url);
if (key_exists("type",$value)) {
    if($value['type'] == "img") {
        header("Location:"."https://resource.dayepao.com/photo/$o/$img");
    }
}
?>