<?php
$o = "bingHD";
$imgs = scandir("/www/wwwroot/img.dayepao.com/img/$o/");
unset($imgs[0]);
unset($imgs[1]);
$num = array_rand($imgs);
$img = $imgs[$num];
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
if (key_exists("type", $value)) {
    switch ($value['type']) {
        case 'img':
            die(header("Location:"."https://img.dayepao.com/img/$o/$img"));
            break;
            
        case 'json':
            header('Content-type:text/json');
            $json = [
                'imgurl'=>"https://img.dayepao.com/img/$o/$img",
                ];
            die(json_encode($json, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
            break;
        
        default:
            echo "<img style='max-width: 100%;' src='https://img.dayepao.com/img/$o/$img'/>";
            break;
    }
}
else {
    echo "<img style='max-width: 100%;' src='https://img.dayepao.com/img/$o/$img'/>";
}
?>