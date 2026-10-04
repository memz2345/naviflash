                          
  
                                                 
                                                      
  
                                                                      
                                                                        
  
                                                   
                                                             
                          
                                                          
                                                     
              
abstract final class BvAv {
  static const String _table =
      'FcwAPNKTMug3GV5Lj7EJnHpWsx4tb8haYeviqBz6rkCy12mUSDQX9RdoZf';
  static const int _base = 58;
  static const int _xorCode = 23442827791579;
  static const int _maskCode = 2251799813685247;                 
  static const int _maxAid = 1 << 51;

  static final Map<int, int> _invData = _buildInvData();

  static Map<int, int> _buildInvData() {
    final map = <int, int>{};
    for (var i = 0; i < _table.length; i++) {
      map[_table.codeUnitAt(i)] = i;
    }
    return map;
  }

                                           
     
                                                        
                                   
  static int? decode(String bv) {
    final b = bv.trim();
    if (b.length != 12) return null;
    final head = b.substring(0, 2).toLowerCase();
    if (head != 'bv') return null;
    final arr = b.codeUnits.sublist(3);       
    final t0 = arr[0];
    arr[0] = arr[6];
    arr[6] = t0;
    final t1 = arr[1];
    arr[1] = arr[4];
    arr[4] = t1;
    var tmp = 0;
    for (final c in arr) {
      final v = _invData[c];
      if (v == null) return null;
      tmp = tmp * _base + v;
    }
    return (tmp & _maskCode) ^ _xorCode;
  }

                                                    
  static String? encode(int av) {
    if (av <= 0 || av >= _maxAid) return null;
    final bytes = <String>['B', 'V', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0'];
    var bvIndex = bytes.length - 1;
    var tmp = (_maxAid | av) ^ _xorCode;
    while (tmp > 0) {
      bytes[bvIndex--] = _table[tmp % _base];
      tmp = tmp ~/ _base;
    }
    final a3 = bytes[3];
    bytes[3] = bytes[9];
    bytes[9] = a3;
    final a4 = bytes[4];
    bytes[4] = bytes[7];
    bytes[7] = a4;
    return bytes.join();
  }
}
