
const int depth = 5;

const static float DIST_MAX = 100000.0;

void translate(inout float4x4 origin, in float3 dir)
{
	float4x4 trans = float4x4(1.0, 0.0, 0.0, 0.0,
		0.0, 1.0, 0.0, 0.0,
		0.0, 0.0, 1.0, 0.0,
		dir.x, dir.y, dir.z, 1.0);
	origin = origin * trans;
}

struct RAY
{
	float3 origin;
	float3 dir;
	float IOR;
};

struct GEOM
{
	float3 color;
	int type;
	int texturetype;

	int reflective;
	int refractive;
	float reflectivity;

	float indexOfRefraction;
	int subsurfaceScatter;
	int emittance;

	float4x4 model;
	float4x4 invmodel;
	float4x4 transinvmodel;
};

float3 _initray;

float getrandom(float3 noise, float seed)
{
	return frac(sin(dot(_initray + seed, noise))* 43758.5453 + seed);
}

float rand(float2 co)
{
	float a = 12.9898, b = 78.233, c = 43758.5453;
	float dt = dot(co.xy, float2(a, b));
	dt = fmod(dt,3.14);
	return frac(sin(dt) *c);
}

float3 caculateRandomDirectionInHemisphere(float seed, float3 normal)
{
	float u = getrandom(float3(12.9898, 78.233, 151.7182), seed);
	float v = getrandom(float3(63.7264, 10.873, 623.6736), seed);
	float up = sqrt(u);
	float over = sqrt(1.0 - up*up);
	float around = v*3.1415926 *2.0;

	float3 directionNotNormal;
	if (abs(normal.x) < 0.577350269189)
		directionNotNormal = float3(1, 0, 0);
	else if (abs(normal.y) < 0.577350269189)
		directionNotNormal = float3(0, 1, 0);
	else
		directionNotNormal = float3(0, 0, 1);

	float3 perpendicularDir1 = normalize(cross(normal, directionNotNormal));
	float3 perpendicularDir2 = normalize(cross(normal, perpendicularDir1));

	return (up *normal) + cos(around) *over * perpendicularDir1 + sin(around) *over * perpendicularDir2;
}


struct INTERSECT
{
	float3 p;
	float3 n;
	int g;
};

float3 getPointOnRay(RAY r, float t)
{
	return r.origin + (t - 0.0001) * normalize(r.dir);
}



float intersectSphere(RAY r,float3 center,float radius, out float3 normal,out float3 hitpos)
{
	float3 rc = center - r.origin;
	r.dir = normalize(r.dir);

	float rdotv = dot(rc, r.dir);
	float delta = rdotv*rdotv - (dot(rc, rc) - radius * radius);
	if (delta < 0)
	{
		return -1.0;
	}

	float t;

	float sqrtdelta = sqrt(delta);
	float t1 = rdotv + sqrtdelta;
	float t2 = rdotv - sqrtdelta;

	t = min(t1, t2);
	hitpos = getPointOnRay(r, t);
	normal = normalize(hitpos - center);
	return t;
}


bool intersectWorld(RAY r, inout INTERSECT intersect, inout float dist)
{
	float3 normal, hitpos;
	float t;
	float t_max = 10000;
	t = intersectSphere(r, 0, 1.5, normal, hitpos);
	if (t > 0 && t < t_max)
	{
		t_max = t;
		intersect.p = hitpos;
		intersect.n = normal;
		intersect.g = 1;
	}

	t = intersectSphere(r, float3(2.5,0.5,0.5), 3, normal, hitpos);
	if (t > 0 && t < t_max)
	{
		t_max = t;
		intersect.p = hitpos;
		intersect.n = normal;
		intersect.g = 2;
	}

	t = intersectSphere(r, float3(1.5, 3, -0.5), 0.5, normal, hitpos);
	if (t > 0 && t < t_max)
	{
		t_max = t;
		intersect.p = hitpos;
		intersect.n = normal;
		intersect.g = 0;
	}


	dist = t_max;
	if (t_max < 10000)
		return true;
	return false;
}


void pathTracer(inout RAY r, int rayDepth, inout float3 col)
{
	float r1 = rand(r.origin.xy);
	float3 dir1 = normalize(caculateRandomDirectionInHemisphere(_Time.y + r1,r.dir));
	r.dir = lerp(r.dir, dir1, 0.001);

	float3 color1 = float3(1.0, 0, 0);
	float3 color2 = float3(0, 1.0, 0);

	float3 tempCol = 0;

	float tmax = DIST_MAX;
	float t = 0;

	float3 normal, hitpos;

	INTERSECT intersect;
	intersect.p = 0;
	intersect.n = 0;

	float3 colorMask = 1.0;

	float shift = 0.001;

	for (int i = 0; i < 5; i++)
	{
		float seed = _Time.x + float(i);
		//t = intersectSphere(r, 0, 0.5,normal,hitpos);

		bool iscoli = intersectWorld(r, intersect, t);

		if (iscoli)
		{
			if (intersect.g == 0)
			{
				colorMask = colorMask;
				col = colorMask;
				return;
			}
			else
			{
				float3 gcol = color1;
				if (intersect.g == 2)
					gcol = color2;
				colorMask *= gcol;
				tempCol = colorMask;
			}
			

			float random = rand(intersect.p.xy);
			r.dir = normalize(caculateRandomDirectionInHemisphere(seed + random, intersect.n));
			r.origin = intersect.p + r.dir *shift;
		}
		col += tempCol;
	}

	
}