<!--- Native Adobe/Lucee regression. Run only through a loopback-only test runner. --->
<cfif NOT structKeyExists(REQUEST,"bannerImageTestAuthorized") OR NOT REQUEST.bannerImageTestAuthorized><cfheader statuscode="404"/><cfabort/></cfif>
<cfinclude template="#VARIABLES.bannerImageTestHelper#"/>
<cfscript>
checks=0; failures=[];
function check(required boolean condition,required string label) {
    checks++; if (!arguments.condition) arrayAppend(failures,arguments.label);
}
function accepts(required string source,required string extension,required numeric width,required numeric height) {
    var before=hash(fileReadBinary(arguments.source),'SHA-256');
    try {
        var info=bannerImageMetadata(arguments.source);
        check(info.extension EQ arguments.extension && info.width EQ arguments.width && info.height EQ arguments.height,"valid " & arguments.extension & " detected with correct dimensions " & arguments.width & "x" & arguments.height);
        check(before EQ hash(fileReadBinary(arguments.source),'SHA-256'),"original " & arguments.extension & " bytes preserved");
    } catch(any e) { check(false,"valid " & arguments.extension & " rejected: " & e.message); }
}
function rejects(required string source,string reason="") {
    try { bannerImageMetadata(arguments.source); check(false,"invalid/oversized " & getFileFromPath(arguments.source) & " accepted"); }
    catch(any e) { check(e.type EQ 'AdsV1.Validation' && (!len(arguments.reason) || find(arguments.reason,e.message)),"reject " & getFileFromPath(arguments.source) & " through image validation " & arguments.reason); }
}
scratch=getTempDirectory() & 'banner-image-regression-' & lCase(replace(createUUID(),'-','','all'));
directoryCreate(scratch);
try {
    small=createObject('java','java.awt.image.BufferedImage').init(7,9,1);
    for (format in ['jpg','png']) {
        source=scratch & '/valid.' & format;
        createObject('java','javax.imageio.ImageIO').write(small,format,createObject('java','java.io.File').init(source));
        accepts(source,format,7,9);
    }
    banner=createObject('java','java.awt.image.BufferedImage').init(1140,451,1);
    createObject('java','javax.imageio.ImageIO').write(banner,'jpg',createObject('java','java.io.File').init(scratch & '/banner.jpg'));
    accepts(scratch & '/banner.jpg','jpg',1140,451);
    fileCopy(scratch & '/valid.jpg',scratch & '/renamed.png');
    accepts(scratch & '/renamed.png','jpg',7,9);
    fileWrite(scratch & '/one.gif',binaryDecode('R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==','base64'));
    accepts(scratch & '/one.gif','gif',1,1);
    gifHex=binaryEncode(fileReadBinary(scratch & '/one.gif'),'hex');
    canvasHex=left(gifHex,12) & '2c01fa00' & mid(gifHex,21,len(gifHex));
    fileWrite(scratch & '/canvas.gif',binaryDecode(canvasHex,'hex'));
    accepts(scratch & '/canvas.gif','gif',300,250);
    imageBlock=mid(gifHex,39,len(gifHex)-40);
    fileWrite(scratch & '/animated.gif',binaryDecode(left(canvasHex,len(canvasHex)-2) & imageBlock & '3b','hex'));
    accepts(scratch & '/animated.gif','gif',300,250);
    fileWrite(scratch & '/fake.jpg','not an image'); rejects(scratch & '/fake.jpg');
    fileWrite(scratch & '/truncated.jpg',binaryDecode('ffd8ffe000104a464946000101','hex')); rejects(scratch & '/truncated.jpg');
    fileWrite(scratch & '/huge-canvas.gif',binaryDecode(left(gifHex,12) & '10271027' & mid(gifHex,21,len(gifHex)),'hex'));
    rejects(scratch & '/huge-canvas.gif','40 megapixels');
    fileWrite(scratch & '/bad-frame.gif',binaryDecode(left(canvasHex,len(canvasHex)-2) & replace(imageBlock,'01000100','10271027') & '3b','hex'));
    rejects(scratch & '/bad-frame.gif');
    // Invalid later-frame offsets must not escape the logical canvas.
    offsetBlock=left(imageBlock,2) & '2c01fa00' & mid(imageBlock,11,len(imageBlock));
    fileWrite(scratch & '/bad-offset.gif',binaryDecode(left(canvasHex,len(canvasHex)-2) & offsetBlock & '3b','hex'));
    rejects(scratch & '/bad-offset.gif');
    oversized=createObject('java','java.io.RandomAccessFile').init(scratch & '/oversize.jpg','rw');
    oversized.setLength(10485761); oversized.close(); rejects(scratch & '/oversize.jpg','10 MiB');
    // Validation/cleanup must release handles even after decoding errors.
    check(arrayLen(directoryList(scratch,false,'path')) EQ 13,"all fixtures remain available for cleanup");
} finally { directoryDelete(scratch,true); }
check(!directoryExists(scratch),"image readers and streams release temporary files");
cfcontent(type='application/json; charset=utf-8',reset=true);
writeOutput(serializeJSON({ok=!arrayLen(failures),checks=checks,failures=failures}));
</cfscript>
