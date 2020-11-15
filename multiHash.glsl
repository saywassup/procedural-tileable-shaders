
// based on: http://briansharpe.wordpress.com/2011/10/01/gpu-texture-free-noise/
vec3 permutePrepareMod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permutePrepareMod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permuteResolve(vec4 x) { return fract( x * (7.0 / 288.0 )); }
vec4 permuteHashInternal(vec4 x) { return fract(x * ((34.0 / 289.0) * x + (1.0 / 289.0))) * 289.0; }

// generates a random number for each of the 4 cell corners
vec4 permuteHash2D(vec4 cell)    
{
    cell = permutePrepareMod289(cell * 32.0);
    return permuteResolve(permuteHashInternal(permuteHashInternal(cell.xzxz) + cell.yyww));
}

// generates 2 random numbers for each of the 4 cell corners
void permuteHash2D(vec4 cell, out vec4 hashX, out vec4 hashY)
{
    cell = permutePrepareMod289(cell);
    hashX = permuteHashInternal(permuteHashInternal(cell.xzxz) + cell.yyww);
    hashY = permuteResolve(permuteHashInternal(hashX));
    hashX = permuteResolve(hashX);
}

// generates a random number for each each input
vec2 hash1D(vec2 x, vec2 y)
{
    // based on: Inigo Quilez, Integer Hash - III, 2017
    uvec4 q = uvec4(uvec2(x * 65536.0), uvec2(y * 65536.0));
    q = 1103515245u * ((q >> 1u) ^ q.yxwz);
    uvec2 n = 1103515245u * (q.xz ^ (q.yw >> 3u));
    return vec2(n) * (1.0 / float(0xffffffffu));
}

// generates two random numbers for each each input
vec4 hash2D(vec2 x, vec2 y)
{
    // based on: Inigo Quilez, Integer Hash - III, 2017
    uvec4 q0 = uvec2(x * 65536.0).xyyx + uvec2(0u, 3115245u).xxyy;
    uvec4 q1 = uvec2(y * 65536.0).xyyx + uvec2(0u, 3115245u).xxyy;
    q0 = 1103515245u * ((q0 >> 1u) ^ q0.yxwz);
    q1 = 1103515245u * ((q1 >> 1u) ^ q1.yxwz);
    uvec4 n = 1103515245u * (uvec4(q0.xz, q1.xz) ^ (uvec4(q0.yw, q1.yw) >> 3u));
    return vec4(n) * (1.0 / float(0xffffffffu));
}

// generates a random number for each of the 4 cell corners
vec4 betterHash2D(vec4 cell)    
{
    vec4 hash;
    hash.xy = hash1D(cell.xy, cell.zy);
    hash.zw = hash1D(cell.xw, cell.zw);;
    return hash;
}

// generates 2 random numbers for each of the 4 cell corners
void betterHash2D(vec4 cell, out vec4 hashX, out vec4 hashY)
{
    vec4 hash0 = hash2D(cell.xy, cell.zy);
    vec4 hash1 = hash2D(cell.xw, cell.zw);
    hashX = vec4(hash0.xz, hash1.xz);
    hashY = vec4(hash0.yw, hash1.yw);
}

void betterHash2D(vec4 coords0, vec4 coords1, out vec4 hashX, out vec4 hashY)
{
    vec4 hash0 = hash2D(coords0.xy, coords0.zw);
    vec4 hash1 = hash2D(coords1.xy, coords1.zw);
    hashX = vec4(hash0.xz, hash1.xz);
    hashY = vec4(hash0.yw, hash1.yw);
}

// 3D

// generates a random number for each of the 8 cell corners
void permuteHash3D(vec3 cell, vec3 cellPlusOne, out vec4 lowHash, out vec4 highHash)     
{
    cell = permutePrepareMod289(cell);
    cellPlusOne = step(cell, vec3(287.5)) * cellPlusOne;

    highHash = permuteHashInternal(permuteHashInternal(vec2(cell.x, cellPlusOne.x).xyxy) + vec2(cell.y, cellPlusOne.y).xxyy);
    lowHash = permuteResolve(permuteHashInternal(highHash + cell.zzzz));
    highHash = permuteResolve(permuteHashInternal(highHash + cellPlusOne.zzzz));
}

// generates a random number for each of the 8 cell corners
void fastHash3D(vec3 cell, vec3 cellPlusOne, out vec4 lowHash, out vec4 highHash)
{
    // based on: https://briansharpe.wordpress.com/2011/11/15/a-fast-and-simple-32bit-floating-point-hash-function/
    const vec2 kOffset = vec2(50.0, 161.0);
    const float kDomainScale = 289.0;
    const float kLargeValue = 635.298681;
    const float kk = 48.500388;
    
    //truncate the domain, equivalant to mod(cell, kDomainScale)
    cell -= floor(cell.xyz * (1.0 / kDomainScale)) * kDomainScale;
    cellPlusOne = step(cell, vec3(kDomainScale - 1.5)) * cellPlusOne;

    vec4 r = vec4(cell.xy, cellPlusOne.xy) + kOffset.xyxy;
    r *= r;
    r = r.xzxz * r.yyww;
    highHash.xy = vec2(1.0 / (kLargeValue + vec2(cell.z, cellPlusOne.z) * kk));
    lowHash = fract(r * highHash.xxxx);
    highHash = fract(r * highHash.yyyy);
}

// generates a random number for each of the 8 cell corners
void betterHash3D(vec3 cell, vec3 cellPlusOne, out vec4 lowHash, out vec4 highHash)
{
    cell *= 4096.0;
    cellPlusOne *= 4096.0;
    uvec4 cells = uvec4(cell.xy, cellPlusOne.xy);  
    uvec4 hash = ihash1D(ihash1D(cells.xzxz) + cells.yyww);
    
    lowHash = vec4(ihash1D(hash + uint(cell.z))) * (1.0 / float(0xffffffffu));
    highHash = vec4(ihash1D(hash + uint(cellPlusOne.z))) * (1.0 / float(0xffffffffu));
}

// @note Can change to (faster to slower order): permuteHash2D, betterHash2D
// Each has a tradeoff between quality and speed, some may also experience artifacts for certain ranges and are not realiable.
#define multiHash2D betterHash2D

// @note Can change to (faster to slower order): fastHash3D, permuteHash3D, betterHash3D
// Each has a tradeoff between quality and speed, some may also experience artifacts for certain ranges and are not realiable.
#define multiHash3D betterHash3D

void smultiHash2D(vec4 cell, out vec4 hashX, out vec4 hashY)
{
    multiHash2D(cell, hashX, hashY);
    hashX = hashX * 2.0 - 1.0; 
    hashY = hashY * 2.0 - 1.0;
}