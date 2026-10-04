// Shape array uniforms - 6 floats per shape (type, centerX, centerY, sizeW, sizeH, cornerRadius)
// Reduced from 64 to 16 shapes to fit Impeller's uniform buffer limit (16 * 6 = 96 floats vs 384)
#ifndef MAX_SHAPES
#define MAX_SHAPES 16
#endif

float sdfRRect( in vec2 p, in vec2 b, in float r ) {
    float shortest = min(b.x, b.y);
    r = min(r, shortest);
    vec2 q = abs(p)-b+r;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r;
}

float sdfRect(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdfSquircle(vec2 p, vec2 b, float r) {
    float shortest = min(b.x, b.y);
    r = min(r, shortest);

    vec2 q = abs(p) - b + r;
    
    vec2 maxQ = max(q, 0.0);
    return min(max(q.x, q.y), 0.0) + sqrt(maxQ.x * maxQ.x + maxQ.y * maxQ.y) - r;
}

float sdfEllipse(vec2 p, vec2 r) {
    r = max(r, 1e-4);
    
    vec2 invR = 1.0 / r;
    vec2 invR2 = invR * invR;
    
    vec2 pInvR = p * invR;
    float k1 = length(pInvR);
    
    vec2 pInvR2 = p * invR2;
    float k2 = length(pInvR2);
    
    return (k1 * (k1 - 1.0)) / max(k2, 1e-4);
}

float smoothUnion(float d1, float d2, float k) {
    if (k <= 0.0) {
        return min(d1, d2);
    }
    float e = max(k - abs(d1 - d2), 0.0);
    return min(d1, d2) - e * e * 0.25 / k;
}

float getShapeSDF(float type, vec2 p, vec2 center, vec2 size, float r) {
    if (type == 1.0) { // squircle
        return sdfSquircle(p - center, size / 2.0, r);
    }
    if (type == 2.0) { // ellipse
        return sdfEllipse(p - center, size / 2.0);
    }
    if (type == 3.0) { // rounded rectangle
        return sdfRRect(p - center, size / 2.0, r);
    }
    return 1e9; // none
}

// Reads shape data directly from the uShapeData uniform.
// Note: the uniform must be declared in the including shader before
// including this file, and indices must be constant expressions for
// SkSL compatibility (arrays cannot be dynamically indexed in SkSL).
#define SHAPE_AT(index, point) getShapeSDF( \
    uShapeData[(index) * 6], \
    point, \
    vec2(uShapeData[(index) * 6 + 1], uShapeData[(index) * 6 + 2]), \
    vec2(uShapeData[(index) * 6 + 3], uShapeData[(index) * 6 + 4]), \
    uShapeData[(index) * 6 + 5])

float sceneSDF(vec2 p, float blend) {
    int numShapes = int(uNumShapes);
    if (numShapes == 0) {
        return 1e9;
    }
    
    float result = SHAPE_AT(0, p);
    
    // Fully unrolled (constant indices are required for SkSL output).
    // Uniform branches make the cost equivalent to a dynamic loop.
    if (numShapes >= 2) { result = smoothUnion(result, SHAPE_AT(1, p), blend); }
    if (numShapes >= 3) { result = smoothUnion(result, SHAPE_AT(2, p), blend); }
    if (numShapes >= 4) { result = smoothUnion(result, SHAPE_AT(3, p), blend); }
    if (numShapes >= 5) { result = smoothUnion(result, SHAPE_AT(4, p), blend); }
    if (numShapes >= 6) { result = smoothUnion(result, SHAPE_AT(5, p), blend); }
    if (numShapes >= 7) { result = smoothUnion(result, SHAPE_AT(6, p), blend); }
    if (numShapes >= 8) { result = smoothUnion(result, SHAPE_AT(7, p), blend); }
    if (numShapes >= 9) { result = smoothUnion(result, SHAPE_AT(8, p), blend); }
    if (numShapes >= 10) { result = smoothUnion(result, SHAPE_AT(9, p), blend); }
    if (numShapes >= 11) { result = smoothUnion(result, SHAPE_AT(10, p), blend); }
    if (numShapes >= 12) { result = smoothUnion(result, SHAPE_AT(11, p), blend); }
    if (numShapes >= 13) { result = smoothUnion(result, SHAPE_AT(12, p), blend); }
    if (numShapes >= 14) { result = smoothUnion(result, SHAPE_AT(13, p), blend); }
    if (numShapes >= 15) { result = smoothUnion(result, SHAPE_AT(14, p), blend); }
    if (numShapes >= 16) { result = smoothUnion(result, SHAPE_AT(15, p), blend); }
    
    return result;
}
