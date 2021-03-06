#version 300 es

uniform mat4 u_Model;       // The matrix that defines the transformation of object
uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
uniform float u_Time;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader
in vec4 vs_Nor;             // The array of vertex normals passed to the shader
in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex.
out vec4 fs_Col;            // The color of each vertex.
out vec4 fs_Pos;

//NOISE FUNCTION (Found online from https://github.com/ashima/webgl-noise)
float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

//Custom fractal brownian motion based on above noise function
float fbm(vec3 p) {
    float n = 0.0;
    float w = 0.5;
    for (int i = 0; i < 5; i++) {
        n += noise(p) * w;
        w *= 0.5;
        p *= 2.0;
        p += vec3(100);
    }
    return n;
}

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light.

void main()
{
    fs_Col = vs_Col; // Pass the vertex colors to the fragment shader for interpolation

    vec4 height = normalize(fbm(vec3(vs_Pos.xyz)+vec3(u_Time*0.01, u_Time*0.01, u_Time*0.01))/1.5+vs_Nor);

    vec4 pos = vs_Pos + height;
    fs_Pos = pos;

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);

    vec4 modelposition = u_Model * pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position renders the final positions of the geometry's vertices
}
