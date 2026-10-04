                                         
                                                
                                                         
                                                       
                                              
import 'dart:typed_data';

abstract final class MotionPhotoService {
                                                 
  static Uint8List? build({
    required Uint8List jpeg,
    required Uint8List mp4,
  }) {
    if (jpeg.length < 4 || jpeg[0] != 0xFF || jpeg[1] != 0xD8) return null;
    if (mp4.isEmpty) return null;

    final xmp = _xmpPacket(mp4.length);
    final app1 = _buildApp1Segment(xmp);
    if (app1 == null) return null;

    final insertAt = _appnEndOffset(jpeg);
    final out = BytesBuilder(copy: false);
    out.add(jpeg.sublist(0, insertAt));
    out.add(app1);
    out.add(jpeg.sublist(insertAt));
    out.add(mp4);
    return out.toBytes();
  }

                                                                  
  static Uint8List _xmpPacket(int videoLength) {
    final xmp = '''
<?xpacket begin="\uFEFF" id="W5M0MpCehiHzreSzNTczkc9d"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="NaviFlash">
 <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <rdf:Description rdf:about=""
    xmlns:GCamera="http://ns.google.com/photos/1.0/camera/"
    xmlns:Container="http://ns.google.com/photos/1.0/container/"
    xmlns:Item="http://ns.google.com/photos/1.0/container/item/"
    GCamera:MotionPhoto="1"
    GCamera:MotionPhotoVersion="1"
    GCamera:MotionPhotoPresentationTimestampUs="0"
    GCamera:MicroVideo="1"
    GCamera:MicroVideoVersion="1"
    GCamera:MicroVideoOffset="$videoLength"
    GCamera:MicroVideoPresentationTimestampUs="0">
   <Container:Directory>
    <rdf:Seq>
     <rdf:li rdf:parseType="Resource">
      <Container:Item Item:Mime="image/jpeg" Item:Semantic="Primary" Item:Length="0" Item:Padding="0"/>
     </rdf:li>
     <rdf:li rdf:parseType="Resource">
      <Container:Item Item:Mime="video/mp4" Item:Semantic="MotionPhoto" Item:Length="$videoLength" Item:Padding="0"/>
     </rdf:li>
    </rdf:Seq>
   </Container:Directory>
  </rdf:Description>
 </rdf:RDF>
</x:xmpmeta>
<?xpacket end="w"?>''';
    return Uint8List.fromList(xmp.codeUnits);
  }

                                 
  static Uint8List? _buildApp1Segment(Uint8List xmp) {
    const namespace = 'http://ns.adobe.com/xap/1.0/\x00';
    final ns = namespace.codeUnits;
    final payload = ns.length + xmp.length;
                               
    final segmentLength = payload + 2;
    if (segmentLength > 0xFFFF) return null;
    final out = Uint8List(2 + segmentLength);
    out[0] = 0xFF;
    out[1] = 0xE1;
    out[2] = (segmentLength >> 8) & 0xFF;
    out[3] = segmentLength & 0xFF;
    out.setRange(4, 4 + ns.length, ns);
    out.setRange(4 + ns.length, out.length, xmp);
    return out;
  }

                                                
  static int _appnEndOffset(Uint8List jpeg) {
    var i = 2;
    while (i + 4 <= jpeg.length) {
      if (jpeg[i] != 0xFF) break;
      final marker = jpeg[i + 1];
      final isAppOrCom = (marker >= 0xE0 && marker <= 0xEF) || marker == 0xFE;
      if (!isAppOrCom) break;
      final len = (jpeg[i + 2] << 8) | jpeg[i + 3];
      if (len < 2) break;
      i += 2 + len;
      if (i > jpeg.length) return 2;
    }
    return i;
  }
}
