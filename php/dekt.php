<html>
<head>
<meta charset="utf-8">
<title>第二课堂</title>
</head>
<style>
input[type=text], select {
    width: 100%;
    padding: 30px 20px;
    margin: 8px 0;
    display: inline-block;
    border: 1px solid #ccc;
    border-radius: 4px;
    box-sizing: border-box;
}

input[type=submit] {
    width: 100%;
    background-color: #4CAF50;
    color: white;
    padding: 14px 20px;
    margin: 8px 0;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

input[type=submit]:hover {
    background-color: #45a049;
}

div {
    position:relative;
    top:150px;
    border-radius: 5px;
    background-color: #f2f2f2;
    padding: 20px;
}
img {
    position:relative;
    top:150px;
}
</style>

<body>
<div>
    <form action="<?php echo $_SERVER['PHP_SELF'] ?>" method="post">
        <label for="xuehao" style="font-size:30px;">学号:</label>
        <input type="text" name="xuehao">
        <input type="submit" style="font-size:30px;" value="提交">
    </form>
</div>
</body>
</html>

<?php
function downFile($url,$path){
    $arr=parse_url($url);
    $file=file_get_contents($url);
    file_put_contents($path,$file);
}
function pdf2png2($pdf, $path)
{
    try {
        $im = new Imagick();
        $im->setCompressionQuality(100);
        $im->setResolution(120, 120);//设置分辨率 值越大分辨率越高
        $im->readImage($pdf);
 
        $canvas = new Imagick();
        $imgNum = $im->getNumberImages();
        //$canvas->setResolution(120, 120);
        foreach ($im as $k => $sub) {
            $sub->setImageFormat('png');
            //$sub->setResolution(120, 120);
            $sub->stripImage();
            $sub->trimImage(0);
            $width  = $sub->getImageWidth() + 10;
            $height = $sub->getImageHeight() + 10;
            if ($k + 1 == $imgNum) {
                $height += 10;
            } //最后添加10的height
            $canvas->newImage($width, $height, new ImagickPixel('white'));
            $canvas->compositeImage($sub, Imagick::COMPOSITE_DEFAULT, 5, 5);
        }
 
        $canvas->resetIterator();
        $canvas->appendImages(true)->writeImage($path);
    } catch (Exception $e) {
        throw $e;
    }
}
function deldir($dir) {
    //先删除目录下的文件：
    $dh=opendir($dir);
    while ($file=readdir($dh)) {
       if($file!="." && $file!="..") {
          $fullpath=$dir."/".$file;
          if(!is_dir($fullpath)) {
             unlink($fullpath);
          } else {
             deldir($fullpath);
          }
       }
    }
  
    closedir($dh);
    //删除当前文件夹：
    //if(rmdir($dir)) {
    //   return true;
    //} else {
    //   return false;
    //}
 }
function del_file_by_time($dir,$n){
    if(is_dir($dir)){
        if($dh=opendir($dir)){
            while (false !== ($file = readdir($dh))){
                if($file!="." && $file!=".."){
                    $fullpath=$dir."/".$file;
                    if(!is_dir($fullpath)){
                        $filedate=filemtime($fullpath);
                        $minutes=round((time()-$filedate)/60);
                        if($minutes>$n)
                            unlink($fullpath); //删除文件
                    }
                }
            }
        }
        closedir($dh);
    }
}
if(!empty($_POST["xuehao"])){
    del_file_by_time("temp",30);
    $xuehao = $_POST["xuehao"];
    $time = time();
    $url = 'https://zjczs.scu.edu.cn/ccyl-api/app/credit/exportPdf?userId='.$xuehao.'&creditIds=&selectedAll=true';
    $pdfname = 'temp/'.$xuehao."-".$time.".pdf";
    $pngname = 'temp/'.$xuehao."-".$time.".png";
    downFile("$url","$pdfname");
    pdf2png2("$pdfname", "$pngname");  // ImageMagick配置文件位置: /etc/ImageMagick-6/policy.xml
    echo "<img style='max-width: 100%;' src=\"$pngname\"/>";
}
?>