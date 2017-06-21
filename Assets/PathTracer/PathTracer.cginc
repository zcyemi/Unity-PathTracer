
const static int depth = 5;

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
	float4 pos;
	float reflective;
	float refractive;
	float reflectivity;
	float indexOfRefraction;

	float3 color;
	float emittance;

	float type;

	float material1;	//sss
	float material2;	
	float material3;
};

struct INTERSECT
{
	float3 p;
	float3 n;
	float3 c;
	GEOM g;
};


int _numberOfObjects;
StructuredBuffer<GEOM> _buffer;

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

float3 hemiSphereSampling(float seed, float3 normal)
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

float intersectPlane(RAY r, float3 center, float3 dir, out float3 normal, out float3 hitpos)
{
	dir = normalize(dir);
	float3 rd = r.origin - center;
	float ndotd = dot(dir,rd);
	float len = abs(ndotd);


	float ndott = dot(r.dir, -dir);
	float t = len / ndott;

	normal = dir;
	hitpos = getPointOnRay(r, t);
	return t;
}


bool intersectWorld(RAY r, inout INTERSECT intersect, inout float dist)
{
	float3 normal, hitpos;
	float t;
	float t_max = 10000;

	for (int i = 0; i < _numberOfObjects; i++)
	{
		GEOM geom = _buffer[i];
		if (geom.type == 0)
		{
			//sphere
			t = intersectSphere(r, geom.pos, geom.pos.w, normal, hitpos);
		}
		else if (geom.type == 1)
		{
			t = intersectPlane(r, geom.pos, geom.pos, normal, hitpos);
		}

		if (t > 0 && t < t_max)
		{
			t_max = t;
			intersect.p = hitpos;
			intersect.n = normal;
			intersect.g = geom;
			intersect.c = geom.pos;
		}
	}

	dist = t_max;
	if (t_max < 10000)
		return true;
	return false;
}

////////////////// Rendering Function
float halfLambert(float3 v1, float3 v2)
{
	float dotv = dot(v1, v2);
	return dotv *0.5 + 0.5;
}

float blinnPhongSpecular(float3 normal, float3 lightdir, float power)
{
	float3 halfang = normalize(normal + lightdir);
	return pow(saturate(dot(normal, halfang)), power);
}

float3 subScatter(INTERSECT intersect, float seed)
{
	float3 lightPos = float3(0.2, 2.45, 0);
	float materialThick = 0.5;
	float3 extinctionCoef = 0.7;
	float spec = 15;

	float attenuation = 10 / distance(lightPos, intersect.p);
	float3 lvec = normalize(lightPos - intersect.p);
	float3 norm = normalize(intersect.n);
	float3 evec = normalize(intersect.p - intersect.c);

	float3 dotLN = attenuation *halfLambert(lvec, norm);
	dotLN *= intersect.g.color;

	//indirect term
	float3 indirectTerm = materialThick * max(0.0, dot(-evec, lvec));
	indirectTerm += materialThick *halfLambert(lvec, -norm);
	indirectTerm *= attenuation;
	indirectTerm *= extinctionCoef;

	float3 finalColor = dotLN + indirectTerm;

	float3 specularTerm = blinnPhongSpecular(norm, lvec, spec);

	return finalColor + specularTerm;// +specularTerm;
}


//Fraction Fresnel
struct FRESNEL
{
	float reflectCoef;
	float transmitCoef;
};

FRESNEL caculateFresnel(float3 normal, float3 incident, float incidentIOR, float transmittedIOR)
{
	FRESNEL fresnel;
	incident = normalize(incident);
	normal = normalize(normal);
	float cosThetaI = abs(dot(normal, incident));
	float sinIncident = sqrt(1.0 - cosThetaI * cosThetaI);
	float sinTransmit = incidentIOR / transmittedIOR * sinIncident;
	float cosThetaT = sqrt(1.0 - sinTransmit*sinTransmit);
	if (cosThetaT <= 0.0)
	{
		fresnel.reflectCoef = 1.0;
		fresnel.transmitCoef = 0.0;
		return fresnel;
	}
	else
	{
		//Wiki pedia https://en.wikipedia.org/wiki/Fresnel_equations
		float Rs = (incidentIOR *cosThetaI - transmittedIOR * cosThetaT) / (incidentIOR *cosThetaI + transmittedIOR * cosThetaT);
		Rs *= Rs;
		float Rp = (incidentIOR* cosThetaT - transmittedIOR * cosThetaI) / (incidentIOR* cosThetaT + transmittedIOR * cosThetaI);
		Rp *= Rp;

		fresnel.reflectCoef = 0.5*(Rs + Rp);
		fresnel.transmitCoef = 1.0 - fresnel.reflectCoef;
		return fresnel;
	}
}

/////////////////


void pathTracer(inout RAY r, int rayDepth, inout float3 col)
{

	float3 color1 = float3(1.0, 0.2, 0.3);
	float3 color2 = float3(0.4, 1.0, 0.2);
	float3 error = float3(1.0, 0, 1.0);


	float tmax = DIST_MAX;
	float t = 0;

	float3 normal, hitpos;

	INTERSECT intersect;
	intersect.p = 0;
	intersect.n = 0;

	float3 colorMask = 1.0;

	float shift = 0.001;

	for (int i = 0; i < depth; i++)
	{
		float seed = _Time.x + float(i);
		if (intersectWorld(r, intersect, t))
		{
			GEOM g = intersect.g;
			float random = rand(intersect.p.xy);
			if (g.emittance > 0)
			{
				//light
				colorMask = colorMask * g.color * g.emittance;
				col = colorMask;
				return;
			}
			else if (g.reflective <= 0 && g.refractive <= 0)
			{
				colorMask *= g.color;
				col = colorMask;

				r.dir = normalize(hemiSphereSampling(seed + random, intersect.n));
				r.origin = intersect.p + r.dir *shift;
			}
			else
			{
				bool isInsideOut = dot(r.dir, intersect.n) > 0;
				if (g.refractive > 0)
				{
					float3 random3 = float3(random,rand(intersect.p.xz), rand(intersect.p.yz));
					float oldIOR = r.IOR;
					float newIOR = g.indexOfRefraction;

					float reflect_range = -1.0;
					float eta = oldIOR / newIOR;
					float3 reflectR = reflect(r.dir, intersect.n);
					float3 refractR = refract(r.dir, intersect.n, eta);
					FRESNEL fresnel = caculateFresnel(intersect.n, r.dir, oldIOR, newIOR);

					reflect_range = fresnel.reflectCoef; //reflect rate  reflect+ refract = 1

					float randomnum = getrandom(random, seed);
					if (randomnum < reflect_range)
					{
						r.dir = reflectR;
						r.origin = intersect.p + shift * r.dir;
						if (g.material1 > 0) //subsurface scatter
						{
							colorMask *= subScatter(intersect, random);
						}
					}
					else
					{
						r.dir = refractR;
						r.origin = intersect.p + shift* r.dir;
					}

					if (isInsideOut)
						r.IOR = 1.0;
					else
						r.IOR = newIOR;

					colorMask *= g.color;
					col = colorMask;

				}
				else
				{
					colorMask *= subScatter(intersect, random);
					colorMask *= g.color;
					col = colorMask;
					r.IOR = 1.0;
					r.dir = reflect(r.dir, intersect.n);
					r.origin = intersect.p + r.dir *shift;
				}
			}
		}
		else
		{
			//col = error;
			col = 0;
			return;
		}
	}
	col = 0;
}