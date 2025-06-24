
#include <stdio.h>
#include <string.h>

#include "shape.h"

#define MIN(x, y) ((x) < (y) ? (x) : (y))
#define MAX(x, y) ((x) > (y) ? (x) : (y))



#define test(condition)				\
  do						\
    {						\
      printf ("%-62s: ", #condition);		\
      if (!(condition))				\
	puts ("FAIL");				\
      else					\
	puts ("PASS");				\
    }						\
  while (0)

#define test_fmt(condition, strfmt, ...)	\
  do						\
    {						\
      char buf[2048];				\
      sprintf (buf, strfmt, ##__VA_ARGS__);	\
      printf ("%-62s: ", buf);			\
      if (!(condition))				\
	puts ("FAIL");				\
      else					\
	puts ("PASS");				\
    }						\
  while (0)

typedef struct
{
  UNIT_TYPE x;
  UNIT_TYPE y;
  UNIT_TYPE z;
} Vec3;



/* Smoke tests.  */

static void
test_AABB_to_rgn (void)
{
  struct cuboid_region rgn;
  AABB test_AABB = {
    10.0, 10.0, 10.0,
    23.0, 11.0, 25.0,
  };

  printf ("%s:\n", "AABB_to_rgn");
  region_init (&rgn);
  decompose_AABBs (&rgn, &test_AABB, 1);
  test (rgn.x_size == 2);
  test (rgn.y_size == 2);
  test (rgn.z_size == 2);
  test (rgn.x_edges[0] == 10.0
	&& rgn.x_edges[1] == 23.0);
  test (rgn.y_edges[0] == 10.0
	&& rgn.y_edges[1] == 11.0);
  test (rgn.z_edges[0] == 10.0
	&& rgn.z_edges[1] == 25.0);
  test (region_is_AABB (&rgn, 10, 10, 10));
  test (!region_is_AABB (&rgn, 11, 11, 11));
  test (!region_is_AABB (&rgn, 23, 11, 25));
  region_release (&rgn);
}

static int
AABB_intersect_p (AABB *a, AABB *b)
{
  return (a->x1 <= b->x2
	  && a->y1 <= b->y2
	  && a->z1 <= b->z2
	  && a->x2 >= b->x1
	  && a->y2 >= b->y1
	  && a->z2 >= b->z1);
}

static void
AABB_intersect (AABB *out, AABB *a, AABB *b)
{
  out->x2 = MIN (a->x2, b->x2);
  out->y2 = MIN (a->y2, b->y2);
  out->z2 = MIN (a->z2, b->z2);

  out->x1 = MAX (a->x1, b->x1);
  out->y1 = MAX (a->y1, b->y1);
  out->z1 = MAX (a->z1, b->z1);
}

static AABB *
any_aabb_containing (AABB *aabbs, int n_aabbs, Vec3 *v)
{
  AABB *end = aabbs + n_aabbs, *iter;

  for (iter = aabbs; iter < end; ++iter)
    {
      if (v->x >= iter->x1 && v->y >= iter->y1 && v->z >= iter->z1
	  /* The extrema of AABBs are not labeled occupied.  */
	  && v->x < iter->x2 && v->y < iter->y2 && v->z < iter->z2)
	return iter;
    }

  return NULL;
}

static void
verify_union_identity_1 (struct cuboid_region *region,
			 Vec3 *v, int should_match)
{
  if (should_match)
    test_fmt (region_is_AABB (region, v->x, v->y, v->z),
	      "region_is_AABB (region, %f, %f, %f)",
	      v->x, v->y, v->z);
  else
    test_fmt (!region_is_AABB (region, v->x, v->y, v->z),
	      "!region_is_AABB (region, %f, %f, %f)",
	      v->x, v->y, v->z);
}

/* Verify that every permutation of the AABBs' coordinates that rests
   within one or another AABB is an AABB, and that the converse is
   true of every permutation that does not.  */

static void
verify_union_identity (struct cuboid_region *region,
		       AABB *aabbs, int n_aabbs)
{
  int i, j;

  for (i = 0; i < n_aabbs; ++i)
    {
      AABB *a = aabbs + i;

      for (j = 0; j < n_aabbs; ++j)
	{
	  AABB *b = aabbs + j;
	  Vec3 v;

#define VERIFY_ONE(s1, s2, s3)					\
	  v.x = (s1)->x1;					\
	  v.y = (s2)->y1;					\
	  v.z = (s3)->z1;					\
								\
	  if (any_aabb_containing (aabbs, n_aabbs, &v))		\
	    verify_union_identity_1 (region, &v, 1);		\
	  else							\
	    verify_union_identity_1 (region, &v, 0);		\
								\
	  v.x = (s1)->x2;					\
	  v.y = (s2)->y2;					\
	  v.z = (s3)->z2;					\
								\
	  if (any_aabb_containing (aabbs, n_aabbs, &v))		\
	    verify_union_identity_1 (region, &v, 1);		\
	  else							\
	    verify_union_identity_1 (region, &v, 0);		\

	  VERIFY_ONE (a, a, a);
	  VERIFY_ONE (a, a, b);
	  VERIFY_ONE (b, a, b);
	  VERIFY_ONE (b, a, a);
	  VERIFY_ONE (a, b, b);
	  VERIFY_ONE (a, b, a);
	  VERIFY_ONE (b, b, a);
	  VERIFY_ONE (b, b, b);
#undef VERIFY_ONE
	}
    }
}

static void
test_AABBs_to_rgn (void)
{
  struct cuboid_region rgn;
  AABB test_AABBs[7] = {
    {
      10.0, 10.0, 10.0,
      23.0, 50.0, 25.0,
    },
    {
      41.0, 43.0, 50.0,
      45.0, 60.0, 55.0,
    },
    {
      100.0, 114.0, 78.0,
      200.0, 300.0, 224.0,
    },
    {
      100.0, 100.0, 100.0,
      200.0, 200.0, 200.0,
    },
    {
      -8.0, -8.0, -8.0,
      8.0, 8.0, 8.0,
    },
    {
      -7.5, 16.0, -7.5,
      8.0, 24.0, 8.0,
    },
    {
      -7.0, 32.0, -7.0,
      8.0, 40.0, 8.0,
    },
  };

  printf ("%s:\n", "AABBs_to_rgn");
  region_init (&rgn);
  decompose_AABBs (&rgn, test_AABBs, 7);
  test (region_is_AABB (&rgn, 10, 10, 10));
  verify_union_identity (&rgn, test_AABBs, 7);
  test (region_is_AABB (&rgn, 10, 10, 10));
  test (region_is_AABB (&rgn, 41, 43, 50));
  test (region_is_AABB (&rgn, 100, 100, 100));
  region_release (&rgn);
}

static void
verify_intersection_identity_1 (struct cuboid_region *region, AABB *l,
				int num_l, AABB *r, int num_r)
{
  AABB *iter, *rhs;

  for (iter = l; iter < l + num_l; ++iter)
    {
      AABB test = *iter;
      Vec3 v;

      /* Compute the intersection of ITER with every AABB in L.  */
      for (rhs = r; rhs < r + num_r; ++rhs)
	{
	  if (!AABB_intersect_p (iter, r))
	    continue;

	  AABB_intersect (&test, &test, rhs);

	  /* Verify that the top-left corner of the AABB is a valid
	     AABB.  */
	  v.x = test.x1;
	  v.y = test.y1;
	  v.z = test.z1;
	  verify_union_identity_1 (region, &v, 1);
	}
    }
}

static void
verify_intersection_identity (struct cuboid_region *region, AABB *l,
			      int num_l, AABB *r, int num_r)
{
  verify_intersection_identity_1 (region, l, num_l, r, num_r);
  verify_intersection_identity_1 (region, r, num_r, l, num_l);
}

static void
test_region_ops (void)
{
  struct cuboid_region dest, a, b;
  static AABB basic_cube = {
    -8.0, -8.0, -8.0,
    8.0, 8.0, 8.0,
  };
  static AABB larger_cube = {
    -16.0, -16.0, -16.0,
    16.0, 16.0, 16.0,
  };

  region_init (&dest);
  region_init (&a);
  region_init (&b);
  printf ("%s:\n", "region_ops");
  decompose_AABBs (&a, &basic_cube, 1);
  decompose_AABBs (&b, &basic_cube, 1);
  test (region_equal_p (&a, &b));
  decompose_AABBs (&b, &larger_cube, 1);
  test (!region_equal_p (&a, &b));

  {
    static AABB staggered[3] = {
      {
	-8.0, -8.0, -8.0,
	8.0, 8.0, 8.0,
      },
      {
	-7.5, 16.0, -7.5,
	8.0, 24.0, 8.0,
      },
      {
	-7.0, 32.0, -7.0,
	8.0, 40.0, 8.0,
      },
    };
    static AABB staggered_1[3] = {
      {
	-8.0, -8.0, -8.0,
	4.0, 8.0, 4.0,
      },
      {
	-7.5, 16.0, -7.5,
	4.0, 24.0, 4.0,
      },
      {
	-7.0, 32.0, -7.0,
	4.0, 40.0, 4.0,
      },
    };
    decompose_AABBs (&a, staggered, 3);
    decompose_AABBs (&b, staggered, 3);
    test (region_equal_p (&a, &b));
    decompose_AABBs (&a, staggered, 3);
    decompose_AABBs (&b, staggered_1, 3);
    test (!region_equal_p (&a, &b));

    decompose_AABBs (&a, &larger_cube, 1);
    decompose_AABBs (&b, &basic_cube, 1);
    region_op (&dest, &a, &b, OP_AND);
    test (region_equal_p (&dest, &b));
    test (!region_equal_p (&dest, &a));
    region_op (&dest, &a, &b, OP_OR);
    test (region_equal_p (&dest, &a));
    test (!region_equal_p (&dest, &b));

    decompose_AABBs (&a, staggered, 3);
    decompose_AABBs (&b, staggered_1, 3);
    region_op (&dest, &a, &b, OP_AND); /* staggered_1 & staggered */
    test (region_equal_p (&dest, &b));
    test (!region_equal_p (&dest, &a));
    verify_intersection_identity (&dest, staggered, 3,
				  staggered_1, 3);
    region_op (&dest, &a, &b, OP_OR); /* staggered_1 | staggered */
    test (region_equal_p (&dest, &a));
    test (!region_equal_p (&dest, &b));
  }

  {
    static AABB big_cube = {
      -8.0, -8.0, -8.0,
      8.0, 8.0, 8.0,
    };
    static AABB small_cube = {
      0.0, 0.0, 0.0,
      8.0, 8.0, 8.0,
    };
    static AABB expected[3] = {
      {
	-8.0, -8.0, -8.0,
	8.0, 0.0, 8.0,
      },
      {
	-8.0, 0.0, -8.0,
	0.0, 8.0, 8.0,
      },
      {
	-8.0, 0.0, -8.0,
	8.0, 8.0, 0.0,
      },
    };

    decompose_AABBs (&a, &big_cube, 1);
    decompose_AABBs (&b, &small_cube, 1);
    region_op (&dest, &a, &b, OP_SUB);
    decompose_AABBs (&a, expected, 3);
    test (region_equal_p (&dest, &a));
    test (!region_equal_p (&dest, &b));
    region_op (&a, &dest, &dest, OP_SUB);
    test (region_empty_p (&a));
  }
  region_release (&dest);
  region_release (&a);
  region_release (&b);
}

/* To generate random regions, run:

(let ((x (- (random 100) 50))
      (y (- (random 100) 50))
      (z (- (random 100) 50))
      (width (1+ (random 50)))
      (height (1+ (random 50)))
      (length (1+ (random 50))))
  (insert (format "\n{\n%.2f, %.2f, %.2f, %.2f, %.2f, %.2f,\n},"
		  x y z (+ x width) (+ y height) (+ z length))))

*/

static AABB big_region[] = {
  {
    14.00, 6.00, 37.00, 54.00, 9.00, 40.00,
  },
  {
    -10.00, -10.00, -47.00, 6.00, -8.00, -10.00,
  },
  {
    -45.00, -44.00, 10.00, -5.00, -20.00, 53.00,
  },
  {
    45.00, 12.00, -19.00, 67.00, 52.00, 12.00,
  },
  {
    -17.00, 35.00, -41.00, 26.00, 84.00, -32.00,
  },
  {
    -29.00, 31.00, 46.00, 13.00, 51.00, 73.00,
  },
  {
    -34.00, -32.00, -45.00, 3.00, -25.00, 3.00,
  },
  {
    -47.00, -10.00, 16.00, 2.00, 7.00, 37.00,
  },
  {
    -45.00, 3.00, 47.00, -33.00, 10.00, 48.00,
  },
  {
    -6.00, -13.00, -48.00, 20.00, 24.00, -21.00,
  },
  {
    -28.00, 10.00, -50.00, 15.00, 60.00, -24.00,
  },
  {
    -25.00, -8.00, 39.00, 10.00, 13.00, 56.00,
  },
  {
    -48.00, 11.00, -28.00, -36.00, 29.00, 5.00,
  },
  {
    34.00, 36.00, 42.00, 35.00, 83.00, 88.00,
  },
  {
    10.00, -40.00, -34.00, 44.00, -24.00, -6.00,
  },
  {
    2.00, 48.00, -20.00, 31.00, 61.00, -2.00,
  },
  {
    20.00, 37.00, -11.00, 29.00, 81.00, 1.00,
  },
  {
    -18.00, -44.00, 14.00, 28.00, -39.00, 48.00,
  },
  {
    -19.00, 15.00, 11.00, -2.00, 17.00, 31.00,
  },
  {
    9.00, -42.00, 17.00, 34.00, -33.00, 27.00,
  },
  {
    11.00, 35.00, 30.00, 35.00, 73.00, 42.00,
  },
  {
    -7.00, 16.00, -26.00, 0.00, 17.00, 2.00,
  },
  {
    14.00, 44.00, 32.00, 30.00, 46.00, 60.00,
  },
  {
    36.00, -31.00, -46.00, 44.00, -19.00, 1.00,
  },
  {
    -48.00, 39.00, 43.00, -20.00, 71.00, 92.00,
  },
  {
    13.00, -21.00, 49.00, 43.00, -2.00, 61.00,
  },
  {
    2.00, -12.00, -13.00, 39.00, -7.00, 26.00,
  },
  {
    37.00, -14.00, 29.00, 57.00, -2.00, 38.00,
  },
  {
    -15.00, -42.00, 44.00, -11.00, -4.00, 82.00,
  },
  {
    27.00, -30.00, -8.00, 67.00, 0.00, 18.00,
  },
  {
    -39.00, -22.00, 43.00, -17.00, -20.00, 59.00,
  },
  {
    -11.00, 20.00, -39.00, 13.00, 51.00, -22.00,
  },
  {
    -10.00, 14.00, -2.00, 6.00, 16.00, 9.00,
  },
  {
    43.00, -41.00, -21.00, 91.00, -11.00, -18.00,
  },
  {
    48.00, -4.00, 31.00, 80.00, 26.00, 66.00,
  },
  {
    -20.00, 7.00, -48.00, -14.00, 28.00, -15.00,
  },
  {
    -3.00, -41.00, -20.00, 22.00, 2.00, 29.00,
  },
  {
    26.00, -40.00, -15.00, 72.00, -6.00, 8.00,
  },
  {
    9.00, 26.00, -25.00, 47.00, 34.00, -3.00,
  },
  {
    -19.00, 23.00, 33.00, -5.00, 65.00, 37.00,
  },
  {
    35.00, 39.00, 19.00, 36.00, 67.00, 67.00,
  },
  {
    -29.00, -3.00, -22.00, -26.00, -2.00, 11.00,
  },
  {
    20.00, 16.00, -41.00, 22.00, 25.00, -35.00,
  },
  {
    37.00, 38.00, -30.00, 74.00, 61.00, 4.00,
  },
  {
    -29.00, 48.00, 39.00, -7.00, 85.00, 43.00,
  },
  {
    -31.00, 5.00, -13.00, 18.00, 54.00, -11.00,
  },
  {
    48.00, -39.00, 45.00, 98.00, 9.00, 54.00,
  },
  {
    46.00, 11.00, -41.00, 94.00, 13.00, -24.00,
  },
  {
    2.00, 7.00, 38.00, 38.00, 26.00, 81.00,
  },
  {
    38.00, 6.00, 32.00, 47.00, 7.00, 56.00,
  },
  {
    26.00, 28.00, -10.00, 46.00, 32.00, 3.00,
  },
  {
    -1.00, 22.00, -20.00, 45.00, 48.00, 1.00,
  },
  {
    -7.00, 26.00, 10.00, 35.00, 72.00, 48.00,
  },
  {
    -6.00, 48.00, -1.00, 23.00, 74.00, 45.00,
  },
  {
    4.00, 20.00, -6.00, 23.00, 41.00, 0.00,
  },
  {
    42.00, -31.00, 24.00, 86.00, -13.00, 57.00,
  },
  {
    11.00, -44.00, -4.00, 21.00, -36.00, 23.00,
  },
  {
    -37.00, -37.00, 4.00, 1.00, -15.00, 50.00,
  },
  {
    13.00, 43.00, 22.00, 33.00, 90.00, 27.00,
  },
  {
    49.00, 37.00, 1.00, 53.00, 47.00, 16.00,
  },
  {
    2.00, 18.00, 48.00, 35.00, 35.00, 77.00,
  },
  {
    34.00, 37.00, 26.00, 64.00, 81.00, 29.00,
  },
  {
    -31.00, 17.00, 34.00, -15.00, 63.00, 36.00,
  },
  {
    -10.00, -14.00, -33.00, -7.00, 18.00, 5.00,
  },
  {
    26.00, 9.00, -17.00, 33.00, 43.00, 23.00,
  },
  {
    29.00, 24.00, -10.00, 72.00, 44.00, 16.00,
  },
  {
    41.00, 39.00, 21.00, 73.00, 81.00, 31.00,
  },
  {
    -21.00, -49.00, 10.00, 10.00, -36.00, 37.00,
  },
  {
    -12.00, 41.00, 26.00, 25.00, 67.00, 33.00,
  },
  {
    -27.00, -39.00, -40.00, -4.00, 3.00, -15.00,
  },
  {
    28.00, 35.00, -14.00, 74.00, 76.00, 28.00,
  },
  {
    5.00, -15.00, -23.00, 43.00, -12.00, -3.00,
  },
  {
    -47.00, 31.00, 24.00, -36.00, 47.00, 51.00,
  },
  {
    -47.00, 26.00, -43.00, -41.00, 27.00, -41.00,
  },
  {
    34.00, -32.00, 47.00, 62.00, -16.00, 48.00,
  },
  {
    -19.00, 38.00, 26.00, -15.00, 44.00, 59.00,
  },
  {
    -36.00, 42.00, -45.00, -15.00, 45.00, -39.00,
  },
  {
    -39.00, 22.00, 4.00, -4.00, 24.00, 22.00,
  },
  {
    25.00, 38.00, -11.00, 61.00, 42.00, 25.00,
  },
  {
    -42.00, 3.00, 22.00, -25.00, 27.00, 49.00,
  },
  {
    39.00, -24.00, 29.00, 49.00, 2.00, 41.00,
  },
  {
    -33.00, -47.00, -24.00, 12.00, 1.00, 14.00,
  },
  {
    2.00, -30.00, -46.00, 11.00, 2.00, -37.00,
  },
  {
    14.00, -21.00, -29.00, 46.00, 19.00, 13.00,
  },
  {
    -30.00, -50.00, 1.00, -28.00, -43.00, 35.00,
  },
  {
    33.00, 21.00, -22.00, 57.00, 63.00, -10.00,
  },
  {
    -7.00, 40.00, -10.00, 42.00, 57.00, 23.00,
  },
  {
    6.00, 27.00, -23.00, 44.00, 45.00, -21.00,
  },
  {
    30.00, -20.00, -12.00, 49.00, 26.00, -2.00,
  },
  {
    23.00, 8.00, -9.00, 36.00, 24.00, -3.00,
  },
  {
    -4.00, -39.00, -30.00, 21.00, 10.00, 12.00,
  },
  {
    -1.00, -40.00, 37.00, 24.00, -26.00, 40.00,
  },
  {
    17.00, 36.00, -45.00, 52.00, 60.00, -15.00,
  },
  {
    -41.00, -2.00, -35.00, -12.00, 46.00, -29.00,
  },
  {
    -3.00, -34.00, -36.00, 23.00, -26.00, -19.00,
  },
  {
    -48.00, 36.00, 36.00, -45.00, 67.00, 77.00,
  },
};

static AABB big_region_1[] = {
  {
    -25.00, 22.00, 46.00, 20.00, 23.00, 49.00,
  },
  {
    46.00, -20.00, -5.00, 62.00, 10.00, 23.00,
  },
  {
    47.00, 0.00, -8.00, 89.00, 40.00, 42.00,
  },
  {
    -41.00, 16.00, 32.00, -9.00, 32.00, 67.00,
  },
  {
    -20.00, 29.00, -46.00, -4.00, 32.00, -4.00,
  },
  {
    23.00, -25.00, 11.00, 30.00, -22.00, 36.00,
  },
  {
    3.00, 43.00, -8.00, 39.00, 62.00, 13.00,
  },
  {
    11.00, -14.00, 46.00, 43.00, -3.00, 55.00,
  },
  {
    -29.00, -39.00, 5.00, -5.00, -23.00, 51.00,
  },
  {
    -35.00, 47.00, 5.00, -2.00, 56.00, 51.00,
  },
  {
    -49.00, 15.00, -31.00, -4.00, 19.00, 1.00,
  },
  {
    0.00, 40.00, 42.00, 21.00, 80.00, 64.00,
  },
  {
    23.00, 8.00, 45.00, 30.00, 30.00, 63.00,
  },
  {
    35.00, -12.00, 20.00, 56.00, 17.00, 42.00,
  },
  {
    41.00, 17.00, -24.00, 55.00, 67.00, 13.00,
  },
  {
    34.00, -31.00, -24.00, 74.00, 15.00, -10.00,
  },
  {
    -16.00, -32.00, 32.00, 29.00, 13.00, 80.00,
  },
  {
    -37.00, 23.00, 49.00, -23.00, 26.00, 67.00,
  },
  {
    -49.00, -32.00, -7.00, -6.00, 7.00, 33.00,
  },
  {
    36.00, -48.00, 20.00, 57.00, -4.00, 43.00,
  },
  {
    38.00, 36.00, -43.00, 87.00, 84.00, -36.00,
  },
  {
    8.00, 44.00, -38.00, 14.00, 61.00, -32.00,
  },
  {
    37.00, -24.00, -1.00, 84.00, 23.00, 0.00,
  },
  {
    -25.00, -24.00, -23.00, 1.00, 13.00, -14.00,
  },
  {
    -30.00, 49.00, 34.00, -27.00, 76.00, 72.00,
  },
  {
    10.00, 13.00, 24.00, 21.00, 36.00, 30.00,
  },
  {
    -36.00, 11.00, 7.00, -4.00, 41.00, 40.00,
  },
  {
    -27.00, -21.00, 41.00, -17.00, -15.00, 52.00,
  },
  {
    0.00, -12.00, -42.00, 22.00, 3.00, -31.00,
  },
  {
    3.00, 14.00, 32.00, 44.00, 61.00, 51.00,
  },
  {
    -7.00, -7.00, 28.00, 11.00, 42.00, 56.00,
  },
  {
    -23.00, 47.00, 28.00, 27.00, 68.00, 62.00,
  },
  {
    -28.00, -30.00, -6.00, 4.00, -1.00, 12.00,
  },
  {
    -14.00, -15.00, -30.00, 34.00, 29.00, -14.00,
  },
  {
    -20.00, -8.00, -33.00, 24.00, 16.00, 9.00,
  },
  {
    -12.00, 49.00, -36.00, -2.00, 90.00, -21.00,
  },
  {
    -18.00, -29.00, -30.00, 21.00, -19.00, -9.00,
  },
  {
    14.00, -19.00, -33.00, 30.00, 4.00, -13.00,
  },
  {
    -4.00, 46.00, -33.00, -3.00, 51.00, -11.00,
  },
  {
    32.00, -42.00, -9.00, 76.00, -41.00, -8.00,
  },
  {
    17.00, 45.00, 8.00, 51.00, 77.00, 9.00,
  },
  {
    -12.00, -10.00, 9.00, 3.00, -2.00, 12.00,
  },
  {
    37.00, -50.00, 14.00, 72.00, -8.00, 23.00,
  },
  {
    -32.00, 27.00, 9.00, 10.00, 64.00, 54.00,
  },
  {
    -9.00, -39.00, 7.00, 13.00, -13.00, 27.00,
  },
  {
    0.00, 24.00, 32.00, 13.00, 33.00, 56.00,
  },
  {
    -19.00, -39.00, 4.00, -18.00, -2.00, 21.00,
  },
  {
    -18.00, -46.00, -43.00, 13.00, -41.00, -18.00,
  },
  {
    38.00, -18.00, 5.00, 82.00, 19.00, 29.00,
  },
  {
    33.00, -3.00, -40.00, 76.00, 2.00, 6.00,
  },
  {
    7.00, 0.00, 8.00, 14.00, 35.00, 16.00,
  },
  {
    35.00, 5.00, 12.00, 68.00, 41.00, 32.00,
  },
  {
    -46.00, -9.00, 43.00, -42.00, 38.00, 70.00,
  },
  {
    38.00, 33.00, 34.00, 78.00, 74.00, 75.00,
  },
  {
    -47.00, -30.00, 45.00, -31.00, 20.00, 71.00,
  },
  {
    0.00, 22.00, 43.00, 40.00, 52.00, 67.00,
  },
  {
    -28.00, 44.00, 34.00, 7.00, 61.00, 56.00,
  },
  {
    48.00, 38.00, -41.00, 91.00, 85.00, -20.00,
  },
  {
    46.00, -45.00, 27.00, 70.00, -30.00, 70.00,
  },
  {
    48.00, -21.00, -7.00, 65.00, -10.00, 33.00,
  },
  {
    -33.00, 21.00, 16.00, -24.00, 55.00, 50.00,
  },
  {
    46.00, -34.00, -41.00, 63.00, 8.00, -2.00,
  },
  {
    -48.00, -2.00, 14.00, -23.00, 36.00, 28.00,
  },
  {
    41.00, 8.00, -3.00, 64.00, 32.00, 31.00,
  },
  {
    -5.00, 13.00, -36.00, 36.00, 19.00, 2.00,
  },
  {
    -9.00, -9.00, 39.00, 9.00, 29.00, 52.00,
  },
  {
    -31.00, -1.00, 46.00, -7.00, 47.00, 62.00,
  },
  {
    13.00, -20.00, -15.00, 17.00, 4.00, 18.00,
  },
  {
    26.00, -23.00, 31.00, 27.00, 11.00, 40.00,
  },
  {
    -15.00, 9.00, -10.00, 22.00, 36.00, 38.00,
  },
  {
    -5.00, 36.00, 4.00, 11.00, 70.00, 11.00,
  },
  {
    13.00, -32.00, 13.00, 52.00, 0.00, 35.00,
  },
  {
    -29.00, 45.00, -25.00, 7.00, 51.00, 10.00,
  },
  {
    -7.00, -31.00, 6.00, 35.00, -22.00, 56.00,
  },
  {
    13.00, 11.00, 22.00, 39.00, 42.00, 43.00,
  },
  {
    34.00, -49.00, -26.00, 65.00, -9.00, -20.00,
  },
  {
    9.00, 20.00, 28.00, 35.00, 70.00, 45.00,
  },
  {
    -34.00, -36.00, 10.00, -17.00, -10.00, 38.00,
  },
  {
    -18.00, 16.00, 20.00, 27.00, 28.00, 45.00,
  },
  {
    32.00, -42.00, -8.00, 77.00, -5.00, 34.00,
  },
  {
    26.00, 12.00, 7.00, 62.00, 47.00, 25.00,
  },
  {
    8.00, 42.00, -23.00, 41.00, 85.00, 17.00,
  },
  {
    -17.00, -49.00, 28.00, -9.00, -38.00, 72.00,
  },
  {
    23.00, -9.00, -2.00, 36.00, 36.00, 36.00,
  },
  {
    10.00, 19.00, 31.00, 45.00, 49.00, 69.00,
  },
  {
    38.00, -28.00, -33.00, 59.00, -5.00, -13.00,
  },
  {
    36.00, 17.00, -7.00, 60.00, 23.00, 42.00,
  },
  {
    -50.00, -10.00, -17.00, -25.00, -5.00, 10.00,
  },
  {
    14.00, -15.00, 8.00, 19.00, 4.00, 55.00,
  },
  {
    -22.00, -8.00, 29.00, 7.00, 32.00, 45.00,
  },
  {
    -49.00, 24.00, 7.00, -31.00, 43.00, 57.00,
  },
  {
    -8.00, 10.00, -18.00, 32.00, 28.00, -3.00,
  },
  {
    38.00, 8.00, -21.00, 81.00, 54.00, 17.00,
  },
  {
    10.00, 0.00, 21.00, 26.00, 34.00, 35.00,
  },
  {
    -15.00, 25.00, 39.00, 30.00, 45.00, 43.00,
  },
  {
    30.00, 5.00, -49.00, 76.00, 18.00, -3.00,
  },
  {
    -4.00, -6.00, 22.00, 11.00, 30.00, 33.00,
  },
  {
    12.00, 14.00, -31.00, 58.00, 55.00, 7.00,
  },
  {
    44.00, -14.00, 2.00, 67.00, 32.00, 13.00,
  },
  {
    42.00, -34.00, 47.00, 74.00, -3.00, 90.00,
  },
  {
    -14.00, 6.00, -25.00, 17.00, 53.00, 24.00,
  },
  {
    -19.00, -27.00, 14.00, 4.00, 1.00, 59.00,
  },
  {
    -21.00, 19.00, -41.00, 20.00, 24.00, -36.00,
  },
  {
    21.00, 4.00, 8.00, 41.00, 37.00, 11.00,
  },
  {
    0.00, 23.00, -1.00, 1.00, 51.00, 25.00,
  },
  {
    41.00, -8.00, -47.00, 48.00, 8.00, -39.00,
  },
  {
    -10.00, 48.00, 27.00, 0.00, 66.00, 28.00,
  },
  {
    -6.00, 21.00, -9.00, 26.00, 69.00, 40.00,
  },
  {
    34.00, 9.00, 24.00, 36.00, 58.00, 46.00,
  },
  {
    -9.00, 39.00, 33.00, -1.00, 60.00, 62.00,
  },
  {
    -11.00, 29.00, -5.00, 31.00, 59.00, 33.00,
  },
  {
    19.00, -50.00, 38.00, 33.00, -40.00, 54.00,
  },
  {
    -13.00, -21.00, -41.00, 5.00, 0.00, 9.00,
  },
  {
    41.00, -26.00, 47.00, 77.00, 0.00, 53.00,
  },
  {
    24.00, 33.00, 11.00, 74.00, 83.00, 35.00,
  },
  {
    19.00, 24.00, 44.00, 41.00, 49.00, 55.00,
  },
  {
    2.00, -7.00, 12.00, 8.00, 10.00, 48.00,
  },
  {
    49.00, -35.00, 0.00, 63.00, -2.00, 29.00,
  },
  {
    -31.00, 45.00, 31.00, -12.00, 46.00, 59.00,
  },
  {
    21.00, -11.00, -16.00, 54.00, 34.00, 19.00,
  },
  {
    -19.00, -33.00, 45.00, 14.00, -9.00, 54.00,
  },
  {
    1.00, 22.00, 2.00, 46.00, 69.00, 46.00,
  },
  {
    -41.00, -35.00, -45.00, -11.00, -1.00, -32.00,
  },
  {
    -35.00, -10.00, -35.00, 3.00, 22.00, 11.00,
  },
  {
    -44.00, 14.00, 22.00, -33.00, 22.00, 31.00,
  },
  {
    -32.00, -43.00, 3.00, 8.00, 5.00, 45.00,
  },
  {
    49.00, 3.00, 32.00, 68.00, 24.00, 62.00,
  },
  {
    -14.00, 10.00, -26.00, 34.00, 27.00, 22.00,
  },
  {
    -50.00, 30.00, 47.00, -8.00, 45.00, 59.00,
  },
  {
    4.00, 26.00, 22.00, 44.00, 44.00, 47.00,
  },
  {
    -41.00, -24.00, -5.00, -9.00, -21.00, 18.00,
  },
  {
    28.00, -30.00, 18.00, 67.00, -6.00, 29.00,
  },
  {
    -20.00, -28.00, -25.00, 27.00, 22.00, 17.00,
  },
  {
    -41.00, 46.00, -17.00, -25.00, 90.00, 28.00,
  },
  {
    21.00, 23.00, 39.00, 59.00, 66.00, 67.00,
  },
  {
    36.00, -2.00, -35.00, 80.00, 2.00, -19.00,
  },
  {
    37.00, -36.00, -41.00, 77.00, -9.00, 4.00,
  },
  {
    1.00, 36.00, -5.00, 21.00, 49.00, -2.00,
  },
  {
    -16.00, -12.00, 7.00, 18.00, 15.00, 21.00,
  },
  {
    -21.00, 15.00, -2.00, 0.00, 46.00, 41.00,
  },
  {
    33.00, -43.00, 4.00, 65.00, -34.00, 14.00,
  },
  {
    4.00, -2.00, -41.00, 14.00, 37.00, 0.00,
  },
  {
    1.00, -21.00, 5.00, 41.00, 24.00, 28.00,
  },
  {
    34.00, -21.00, 35.00, 73.00, -19.00, 62.00,
  },
  {
    -25.00, 22.00, 46.00, 20.00, 23.00, 49.00,
  },
  {
    46.00, -20.00, -5.00, 62.00, 10.00, 23.00,
  },
  {
    47.00, 0.00, -8.00, 89.00, 40.00, 42.00,
  },
  {
    -41.00, 16.00, 32.00, -9.00, 32.00, 67.00,
  },
  {
    -20.00, 29.00, -46.00, -4.00, 32.00, -4.00,
  },
  {
    23.00, -25.00, 11.00, 30.00, -22.00, 36.00,
  },
  {
    3.00, 43.00, -8.00, 39.00, 62.00, 13.00,
  },
  {
    11.00, -14.00, 46.00, 43.00, -3.00, 55.00,
  },
  {
    -29.00, -39.00, 5.00, -5.00, -23.00, 51.00,
  },
  {
    -35.00, 47.00, 5.00, -2.00, 56.00, 51.00,
  },
  {
    -49.00, 15.00, -31.00, -4.00, 19.00, 1.00,
  },
  {
    0.00, 40.00, 42.00, 21.00, 80.00, 64.00,
  },
  {
    23.00, 8.00, 45.00, 30.00, 30.00, 63.00,
  },
  {
    35.00, -12.00, 20.00, 56.00, 17.00, 42.00,
  },
  {
    41.00, 17.00, -24.00, 55.00, 67.00, 13.00,
  },
  {
    34.00, -31.00, -24.00, 74.00, 15.00, -10.00,
  },
  {
    -16.00, -32.00, 32.00, 29.00, 13.00, 80.00,
  },
  {
    -37.00, 23.00, 49.00, -23.00, 26.00, 67.00,
  },
  {
    -49.00, -32.00, -7.00, -6.00, 7.00, 33.00,
  },
  {
    36.00, -48.00, 20.00, 57.00, -4.00, 43.00,
  },
  {
    38.00, 36.00, -43.00, 87.00, 84.00, -36.00,
  },
  {
    8.00, 44.00, -38.00, 14.00, 61.00, -32.00,
  },
  {
    37.00, -24.00, -1.00, 84.00, 23.00, 0.00,
  },
  {
    -25.00, -24.00, -23.00, 1.00, 13.00, -14.00,
  },
  {
    -30.00, 49.00, 34.00, -27.00, 76.00, 72.00,
  },
  {
    10.00, 13.00, 24.00, 21.00, 36.00, 30.00,
  },
  {
    -36.00, 11.00, 7.00, -4.00, 41.00, 40.00,
  },
  {
    -27.00, -21.00, 41.00, -17.00, -15.00, 52.00,
  },
  {
    0.00, -12.00, -42.00, 22.00, 3.00, -31.00,
  },
  {
    3.00, 14.00, 32.00, 44.00, 61.00, 51.00,
  },
  {
    -7.00, -7.00, 28.00, 11.00, 42.00, 56.00,
  },
  {
    -23.00, 47.00, 28.00, 27.00, 68.00, 62.00,
  },
  {
    -28.00, -30.00, -6.00, 4.00, -1.00, 12.00,
  },
  {
    -14.00, -15.00, -30.00, 34.00, 29.00, -14.00,
  },
  {
    -20.00, -8.00, -33.00, 24.00, 16.00, 9.00,
  },
  {
    -12.00, 49.00, -36.00, -2.00, 90.00, -21.00,
  },
  {
    -18.00, -29.00, -30.00, 21.00, -19.00, -9.00,
  },
  {
    14.00, -19.00, -33.00, 30.00, 4.00, -13.00,
  },
  {
    -4.00, 46.00, -33.00, -3.00, 51.00, -11.00,
  },
  {
    32.00, -42.00, -9.00, 76.00, -41.00, -8.00,
  },
  {
    17.00, 45.00, 8.00, 51.00, 77.00, 9.00,
  },
  {
    -12.00, -10.00, 9.00, 3.00, -2.00, 12.00,
  },
  {
    37.00, -50.00, 14.00, 72.00, -8.00, 23.00,
  },
  {
    -32.00, 27.00, 9.00, 10.00, 64.00, 54.00,
  },
  {
    -9.00, -39.00, 7.00, 13.00, -13.00, 27.00,
  },
  {
    0.00, 24.00, 32.00, 13.00, 33.00, 56.00,
  },
  {
    -19.00, -39.00, 4.00, -18.00, -2.00, 21.00,
  },
  {
    -18.00, -46.00, -43.00, 13.00, -41.00, -18.00,
  },
  {
    38.00, -18.00, 5.00, 82.00, 19.00, 29.00,
  },
  {
    33.00, -3.00, -40.00, 76.00, 2.00, 6.00,
  },
  {
    7.00, 0.00, 8.00, 14.00, 35.00, 16.00,
  },
  {
    35.00, 5.00, 12.00, 68.00, 41.00, 32.00,
  },
  {
    -46.00, -9.00, 43.00, -42.00, 38.00, 70.00,
  },
  {
    38.00, 33.00, 34.00, 78.00, 74.00, 75.00,
  },
  {
    -47.00, -30.00, 45.00, -31.00, 20.00, 71.00,
  },
  {
    0.00, 22.00, 43.00, 40.00, 52.00, 67.00,
  },
  {
    -28.00, 44.00, 34.00, 7.00, 61.00, 56.00,
  },
  {
    48.00, 38.00, -41.00, 91.00, 85.00, -20.00,
  },
  {
    46.00, -45.00, 27.00, 70.00, -30.00, 70.00,
  },
  {
    48.00, -21.00, -7.00, 65.00, -10.00, 33.00,
  },
  {
    -33.00, 21.00, 16.00, -24.00, 55.00, 50.00,
  },
  {
    46.00, -34.00, -41.00, 63.00, 8.00, -2.00,
  },
  {
    -48.00, -2.00, 14.00, -23.00, 36.00, 28.00,
  },
  {
    41.00, 8.00, -3.00, 64.00, 32.00, 31.00,
  },
  {
    -5.00, 13.00, -36.00, 36.00, 19.00, 2.00,
  },
  {
    -9.00, -9.00, 39.00, 9.00, 29.00, 52.00,
  },
  {
    -31.00, -1.00, 46.00, -7.00, 47.00, 62.00,
  },
  {
    13.00, -20.00, -15.00, 17.00, 4.00, 18.00,
  },
  {
    26.00, -23.00, 31.00, 27.00, 11.00, 40.00,
  },
  {
    -15.00, 9.00, -10.00, 22.00, 36.00, 38.00,
  },
  {
    -5.00, 36.00, 4.00, 11.00, 70.00, 11.00,
  },
  {
    13.00, -32.00, 13.00, 52.00, 0.00, 35.00,
  },
  {
    -29.00, 45.00, -25.00, 7.00, 51.00, 10.00,
  },
  {
    -7.00, -31.00, 6.00, 35.00, -22.00, 56.00,
  },
  {
    13.00, 11.00, 22.00, 39.00, 42.00, 43.00,
  },
  {
    34.00, -49.00, -26.00, 65.00, -9.00, -20.00,
  },
  {
    9.00, 20.00, 28.00, 35.00, 70.00, 45.00,
  },
  {
    -34.00, -36.00, 10.00, -17.00, -10.00, 38.00,
  },
  {
    -18.00, 16.00, 20.00, 27.00, 28.00, 45.00,
  },
  {
    32.00, -42.00, -8.00, 77.00, -5.00, 34.00,
  },
  {
    26.00, 12.00, 7.00, 62.00, 47.00, 25.00,
  },
  {
    8.00, 42.00, -23.00, 41.00, 85.00, 17.00,
  },
  {
    -17.00, -49.00, 28.00, -9.00, -38.00, 72.00,
  },
  {
    23.00, -9.00, -2.00, 36.00, 36.00, 36.00,
  },
  {
    10.00, 19.00, 31.00, 45.00, 49.00, 69.00,
  },
  {
    38.00, -28.00, -33.00, 59.00, -5.00, -13.00,
  },
  {
    36.00, 17.00, -7.00, 60.00, 23.00, 42.00,
  },
  {
    -50.00, -10.00, -17.00, -25.00, -5.00, 10.00,
  },
  {
    14.00, -15.00, 8.00, 19.00, 4.00, 55.00,
  },
  {
    -22.00, -8.00, 29.00, 7.00, 32.00, 45.00,
  },
  {
    -49.00, 24.00, 7.00, -31.00, 43.00, 57.00,
  },
  {
    -8.00, 10.00, -18.00, 32.00, 28.00, -3.00,
  },
  {
    38.00, 8.00, -21.00, 81.00, 54.00, 17.00,
  },
  {
    10.00, 0.00, 21.00, 26.00, 34.00, 35.00,
  },
  {
    -15.00, 25.00, 39.00, 30.00, 45.00, 43.00,
  },
  {
    30.00, 5.00, -49.00, 76.00, 18.00, -3.00,
  },
  {
    -4.00, -6.00, 22.00, 11.00, 30.00, 33.00,
  },
  {
    12.00, 14.00, -31.00, 58.00, 55.00, 7.00,
  },
  {
    44.00, -14.00, 2.00, 67.00, 32.00, 13.00,
  },
  {
    42.00, -34.00, 47.00, 74.00, -3.00, 90.00,
  },
  {
    -14.00, 6.00, -25.00, 17.00, 53.00, 24.00,
  },
  {
    -19.00, -27.00, 14.00, 4.00, 1.00, 59.00,
  },
  {
    -21.00, 19.00, -41.00, 20.00, 24.00, -36.00,
  },
  {
    21.00, 4.00, 8.00, 41.00, 37.00, 11.00,
  },
  {
    0.00, 23.00, -1.00, 1.00, 51.00, 25.00,
  },
  {
    41.00, -8.00, -47.00, 48.00, 8.00, -39.00,
  },
  {
    -10.00, 48.00, 27.00, 0.00, 66.00, 28.00,
  },
  {
    -6.00, 21.00, -9.00, 26.00, 69.00, 40.00,
  },
  {
    34.00, 9.00, 24.00, 36.00, 58.00, 46.00,
  },
  {
    -9.00, 39.00, 33.00, -1.00, 60.00, 62.00,
  },
  {
    -11.00, 29.00, -5.00, 31.00, 59.00, 33.00,
  },
  {
    19.00, -50.00, 38.00, 33.00, -40.00, 54.00,
  },
  {
    -13.00, -21.00, -41.00, 5.00, 0.00, 9.00,
  },
  {
    41.00, -26.00, 47.00, 77.00, 0.00, 53.00,
  },
  {
    24.00, 33.00, 11.00, 74.00, 83.00, 35.00,
  },
  {
    19.00, 24.00, 44.00, 41.00, 49.00, 55.00,
  },
  {
    2.00, -7.00, 12.00, 8.00, 10.00, 48.00,
  },
  {
    49.00, -35.00, 0.00, 63.00, -2.00, 29.00,
  },
  {
    -31.00, 45.00, 31.00, -12.00, 46.00, 59.00,
  },
  {
    21.00, -11.00, -16.00, 54.00, 34.00, 19.00,
  },
  {
    -19.00, -33.00, 45.00, 14.00, -9.00, 54.00,
  },
  {
    1.00, 22.00, 2.00, 46.00, 69.00, 46.00,
  },
  {
    -41.00, -35.00, -45.00, -11.00, -1.00, -32.00,
  },
  {
    -35.00, -10.00, -35.00, 3.00, 22.00, 11.00,
  },
  {
    -44.00, 14.00, 22.00, -33.00, 22.00, 31.00,
  },
  {
    -32.00, -43.00, 3.00, 8.00, 5.00, 45.00,
  },
  {
    49.00, 3.00, 32.00, 68.00, 24.00, 62.00,
  },
  {
    -14.00, 10.00, -26.00, 34.00, 27.00, 22.00,
  },
  {
    -50.00, 30.00, 47.00, -8.00, 45.00, 59.00,
  },
  {
    4.00, 26.00, 22.00, 44.00, 44.00, 47.00,
  },
  {
    -41.00, -24.00, -5.00, -9.00, -21.00, 18.00,
  },
  {
    28.00, -30.00, 18.00, 67.00, -6.00, 29.00,
  },
  {
    -20.00, -28.00, -25.00, 27.00, 22.00, 17.00,
  },
  {
    -41.00, 46.00, -17.00, -25.00, 90.00, 28.00,
  },
  {
    21.00, 23.00, 39.00, 59.00, 66.00, 67.00,
  },
  {
    36.00, -2.00, -35.00, 80.00, 2.00, -19.00,
  },
  {
    37.00, -36.00, -41.00, 77.00, -9.00, 4.00,
  },
  {
    1.00, 36.00, -5.00, 21.00, 49.00, -2.00,
  },
  {
    -16.00, -12.00, 7.00, 18.00, 15.00, 21.00,
  },
  {
    -21.00, 15.00, -2.00, 0.00, 46.00, 41.00,
  },
  {
    33.00, -43.00, 4.00, 65.00, -34.00, 14.00,
  },
  {
    4.00, -2.00, -41.00, 14.00, 37.00, 0.00,
  },
  {
    1.00, -21.00, 5.00, 41.00, 24.00, 28.00,
  },
  {
    34.00, -21.00, 35.00, 73.00, -19.00, 62.00,
  },
};

static void
test_region_ops_1 (void)
{
  static AABB combined[sizeof big_region / sizeof (AABB)
		       + sizeof big_region_1 / sizeof (AABB)];
  struct cuboid_region rgn, rgn1, rgn_combined, dest;
  int size = sizeof big_region / sizeof (AABB);
  int size_1 = sizeof big_region_1 / sizeof (AABB);
  int i;

  region_init (&rgn);
  region_init (&rgn1);
  region_init (&rgn_combined);
  region_init (&dest);
  memcpy (combined, big_region, sizeof big_region);
  memcpy (combined + size, big_region_1, sizeof big_region_1);

  printf ("%s:\n", "region_ops_1");

  for (i = 0; i < 1; ++i)
    {
      struct cuboid_region dest_s;

      region_init (&dest_s);
      test (!decompose_AABBs (&rgn, big_region, size));
      test (!decompose_AABBs (&rgn1, big_region_1, size_1));
      test (!region_copy (&dest, &rgn));
      test (region_equal_p (&dest, &rgn));
      test (!region_copy (&dest, &rgn1));
      test (region_equal_p (&dest, &rgn1));
      test (!region_op (&dest, &rgn, &rgn1, OP_OR));
      test (!region_simplify (&dest_s, &dest));
      test (!decompose_AABBs (&rgn_combined, combined, size + size_1));
      test (region_equal_p (&rgn_combined, &dest));
      test (region_equal_p (&rgn_combined, &dest_s));
      test (!region_op (&rgn, &dest, &rgn1, OP_AND));
      test (region_equal_p (&rgn, &rgn1));
      test (!region_op (&rgn, &dest_s, &rgn1, OP_AND));
      test (region_equal_p (&rgn, &rgn1));
      region_release (&dest_s);
    }

  region_release (&rgn);
  region_release (&rgn1);
  region_release (&rgn_combined);
  region_release (&dest);
}

static void
test_region_optimization (void)
{
  struct cuboid_region rgn, rgn1, rgn2, res;
  AABB big_cube = {
    -16, -16, -16,
    16, 16, 16,
  };
  AABB lesser_cube = {
    -8, -8, -8,
    8, 8, 8,
  };

  printf ("%s:\n", "region_optimization");

  region_init (&rgn);
  region_init (&rgn1);
  region_init (&rgn2);
  region_init (&res);
  /* Complete subsumption.  */
  test (!decompose_AABBs (&rgn1, &big_cube, 1));
  test (!decompose_AABBs (&rgn2, &lesser_cube, 1));
  test (!region_op (&rgn, &rgn1, &rgn2, OP_OR));
  test (!region_simplify (&res, &rgn));
  test (region_equal_p (&res, &rgn));
  test (res.x_size == 2 && res.y_size == 2 && res.z_size == 2);

  /* Subtraction correctness.  */
  test (!decompose_AABBs (&rgn1, &big_cube, 1));
  test (!decompose_AABBs (&rgn2, &lesser_cube, 1));
  test (!region_op (&rgn, &rgn1, &rgn2, OP_SUB));
  test (!region_intersect_p (&rgn, &rgn2));
  test (!region_simplify (&res, &rgn));
  test (region_equal_p (&res, &rgn));
  test (res.x_size == 4 && res.z_size == 4 && res.y_size == 4);

  /* Intersection producing nothing.  */
  test (!region_op (&res, &rgn, &rgn2, OP_AND));
  test (!region_empty_p (&rgn2) && !region_empty_p (&rgn));
  test (region_empty_p (&res));

  /* Intersection producing a perfect cube.  */
  test (!decompose_AABBs (&rgn1, &big_cube, 1));
  test (!decompose_AABBs (&rgn2, &lesser_cube, 1));
  test (region_intersect_p (&rgn1, &rgn2));
  test (!region_op (&rgn, &rgn1, &rgn2, OP_AND));
  test (!region_simplify (&res, &rgn));
  test (region_equal_p (&res, &rgn));
  test (rgn.x_size == 4 && rgn.z_size == 4 && rgn.y_size == 4);
  test (res.x_size == 2 && res.y_size == 2 && res.z_size == 2);

  /* Intersection of a cube with an extruding outgrowth producing four
     edges along one axis reduced to three.  */
  {
    AABB extruding_cube = {
      0, -15, -15,
      45, 15, 15,
    };
    test (!decompose_AABBs (&rgn1, &big_cube, 1));
    test (!decompose_AABBs (&rgn2, &extruding_cube, 1));
    test (!region_op (&rgn, &rgn1, &rgn2, OP_OR));
    test (!region_simplify (&res, &rgn));
    test (region_equal_p (&res, &rgn));
    test (res.x_size == 3 && res.y_size == 4 && res.z_size == 4);
    test (rgn.x_size == 4 && rgn.y_size == 4 && rgn.z_size == 4);
  }

  /* The same applied to multiple axes.  */
  {
    AABB extruding_cube = {
      0, 0, 0,
      45, 45, 45,
    };
    test (!decompose_AABBs (&rgn1, &big_cube, 1));
    test (!decompose_AABBs (&rgn2, &extruding_cube, 1));
    test (!region_op (&rgn, &rgn1, &rgn2, OP_OR));
    test (!region_simplify (&res, &rgn));
    test (region_equal_p (&res, &rgn));
    test (res.x_size == 4 && res.y_size == 4 && res.z_size == 4);
    test (rgn.x_size == 4 && rgn.y_size == 4 && rgn.z_size == 4);
  }

  region_release (&rgn);
  region_release (&rgn1);
  region_release (&rgn2);
  region_release (&res);
}

#define COLLECT_MAX 4096

static int
collect_AABBs (AABB *aabb, void *data, void *data1)
{
  AABB **p = data;
  AABB *base = data1;
  if (*p - base == COLLECT_MAX)
    return 1;
  *(*p)++ = *aabb;
  return 0;
}

static void
test_walk_AABBs (void)
{
  AABB aabbs[COLLECT_MAX], *p = aabbs;
  struct cuboid_region simple, rgn, larger;
  int size_1 = sizeof big_region_1 / sizeof (AABB);
  int size = sizeof big_region / sizeof (AABB);
  static AABB basic_cube = {
    -8.0, -8.0, -8.0,
    8.0, 8.0, 8.0,
  };
  static AABB larger_cube = {
    -16.0, -16.0, -16.0,
    16.0, 16.0, 16.0,
  };
  static AABB difference[] = {
    /* Vertical segments.  */
    {
      -16.0, -16.0, -16.0,
      16.0, -8.0, 16.0,
    },
    {
      -16.0, 8.0, -16.0,
      16.0, 16.0, 16.0,
    },
    /* Horizontal segments.  */
    {
      -16.0, -8.0, -16.0,
      -8.0, 8.0, 16.0,
    },
    {
      8.0, -8.0, -16.0,
      16.0, 8.0, 16.0,
    },
    /* Depthwise segments.  */
    {
      -8.0, -8.0, -16.0,
      8.0, 8.0, -8.0,
    },
    {
      -8.0, -8.0, 8.0,
      16.0, 16.0, 16.0,
    },
  };

  region_init (&simple);
  region_init (&rgn);
  region_init (&larger);

  printf ("%s:\n", "test_walk_aabbs");
  test (!decompose_AABBs (&rgn, big_region, size));
  test (!region_simplify (&simple, &rgn));
  test (!region_walk (&simple, collect_AABBs, &p, aabbs));
  printf ("  Yielded %d AABBs\n", (int) (p - aabbs));
  test (!decompose_AABBs (&rgn, aabbs, p - aabbs));
  test (region_equal_p (&rgn, &simple));
  p = aabbs;
  test (!region_walk (&rgn, collect_AABBs, &p, aabbs));
  test (!decompose_AABBs (&simple, aabbs, p - aabbs));
  test (region_equal_p (&rgn, &simple));

  p = aabbs;
  test (!decompose_AABBs (&rgn, big_region_1, size_1));
  test (!region_simplify (&simple, &rgn));
  test (!region_walk (&simple, collect_AABBs, &p, aabbs));
  printf ("  Yielded %d AABBs\n", (int) (p - aabbs));
  test (!decompose_AABBs (&rgn, aabbs, p - aabbs));
  test (region_equal_p (&rgn, &simple));
  p = aabbs;
  test (!region_walk (&rgn, collect_AABBs, &p, aabbs));
  test (!decompose_AABBs (&simple, aabbs, p - aabbs));
  test (region_equal_p (&rgn, &simple));

  p = aabbs;
  test (!decompose_AABBs (&simple, &basic_cube, 1));
  test (!decompose_AABBs (&larger, &larger_cube, 1));
  test (!region_op (&rgn, &larger, &simple, OP_SUB));
  test (!region_walk (&rgn, collect_AABBs, &p, aabbs));
  test (!decompose_AABBs (&rgn, aabbs, p - aabbs));
  printf ("  Yielded %d AABBs\n", (int) (p - aabbs));
  test (!decompose_AABBs (&simple, difference, 6));
  test (region_equal_p (&simple, &rgn));

  region_release (&simple);
  region_release (&rgn);
  region_release (&larger);
}

static void
test_shorthand_ops (void)
{
  struct cuboid_region dest1, dest, big, lhs, tmp;
  int size_1 = sizeof big_region_1 / sizeof (AABB);
  static AABB basic_cube = {
    -8.0, -8.0, -8.0,
    8.0, 8.0, 8.0,
  };
  static AABB narrow_though_extreme_cube = {
    -0.5, -0.5, -0.5,
    0.5, 0.5, 100.0,
  };
  static AABB narrow_though_extreme_cube_1 = {
    -0.5, -0.5, -0.5,
    0.5, 0.5, 101.0,
  };

  region_init (&dest);
  region_init (&dest1);
  region_init (&big);
  region_init (&lhs);

  printf ("%s:\n", "test_shorthand_ops");
  test (!decompose_AABBs (&big, big_region_1, size_1));
  test (!decompose_AABBs (&lhs, &basic_cube, 1));
  test (!region_subtract (&dest, &big, &basic_cube));
  test (!region_op (&dest1, &big, &lhs, OP_SUB));
  test (region_equal_p (&dest, &dest1));

  test (!decompose_AABBs (&big, big_region_1, size_1));
  test (!region_intersect (&dest, &big, &basic_cube));
  test (!region_op (&dest1, &big, &lhs, OP_AND));
  test (region_equal_p (&dest, &dest1));

  test (!decompose_AABBs (&big, big_region_1, size_1));
  test (!region_union (&dest, &big, &basic_cube));
  test (!region_op (&dest1, &big, &lhs, OP_OR));
  test (region_equal_p (&dest, &dest1));

  test (!region_subtract (&dest, &big, &basic_cube));
  test (!region_contains_p (&dest, &big));
  test (region_contains_p (&big, &dest));
  test (!region_union (&dest1, &dest, &narrow_though_extreme_cube));
  test (!region_contains_p (&big, &dest1));
  test (region_contains_p (&dest1, &dest));
  test (!region_union (&lhs, &dest1, &basic_cube));
  test (region_contains_p (&lhs, &dest));
  test (region_contains_p (&lhs, &dest1));
  test (region_contains_p (&lhs, &big));
  test (!region_contains_p (&big, &lhs));
  test (!region_contains_p (&dest, &lhs));
  test (!region_contains_p (&dest1, &lhs));

  region_init_from_AABB (&tmp, &narrow_though_extreme_cube);
  test (region_contains_p (&lhs, &tmp));
  region_init_from_AABB (&tmp, &narrow_though_extreme_cube_1);
  test (!region_contains_p (&lhs, &tmp));

  region_release (&dest);
  region_release (&dest1);
  region_release (&big);
  region_release (&lhs);
}

static void
test_faces (void)
{
  static AABB OCTET_NPN = {
    0.0, 8.0, 0.0, 8.0, 16.0, 8.0,
  };
  static AABB OCTET_NPP = {
    0.0, 8.0, 8.0, 8.0, 16.0, 16.0,
  };
  static AABB OCTET_PPN = {
    8.0, 0.0, 8.0, 16.0, 8.0, 16.0,
  };
  static AABB OCTET_PPP = {
    8.0, 8.0, 8.0, 16.0, 16.0, 16.0,
  };
  static AABB BOTTOM_AABB = {
    0.0, 0.0, 0.0, 16.0, 8.0, 16.0,
  };

  AABB minecraft_stairs[5];
  AABB reference;
  struct cuboid_region stairs, face, test;
  int i;

  minecraft_stairs[0] = BOTTOM_AABB;
  minecraft_stairs[1] = OCTET_NPN;
  minecraft_stairs[2] = OCTET_PPN;
  minecraft_stairs[3] = OCTET_NPP;
  minecraft_stairs[4] = OCTET_PPP;

  for (i = 0; i < 5; ++i)
    {
      AABB *box = &minecraft_stairs[i];

      box->x1 -= 8.0;
      box->y1 -= 8.0;
      box->z1 -= 8.0;
      box->x2 -= 8.0;
      box->y2 -= 8.0;
      box->z2 -= 8.0;
    }

  region_init (&stairs);
  region_init (&face);
  region_init (&test);

  test (!decompose_AABBs (&stairs, minecraft_stairs, 5));

  /* Bottom face.  */
  test (!region_select_face (&face, &stairs, AXIS_Y, -8.0));
  reference.x1 = -8.0;
  reference.y1 = -8.0;
  reference.z1 = -8.0;
  reference.x2 = 8.0;
  reference.y2 = 8.0;
  reference.z2 = 8.0;
  test (!decompose_AABBs (&test, &reference, 1));
  test (region_equal_p (&face, &test));

  /* Top face.  */
  test (!region_select_face (&face, &stairs, AXIS_Y, 8.0));
  {
    AABB ref1[3];
    ref1[0] = OCTET_PPP;
    ref1[1] = OCTET_NPN;
    ref1[2] = OCTET_NPP;
    ref1[0].y1 = 0;
    ref1[1].y1 = 0;
    ref1[2].y1 = 0;

    for (i = 0; i < 3; ++i)
      {
	AABB *box = &ref1[i];

	box->x1 -= 8.0;
	box->y1 -= 8.0;
	box->z1 -= 8.0;
	box->x2 -= 8.0;
	box->y2 -= 8.0;
	box->z2 -= 8.0;
      }
    test (!decompose_AABBs (&test, ref1, 3));
  }
  test (region_equal_p (&face, &test));

  /* Left face.  */

  test (!region_select_face (&face, &stairs, AXIS_X, -8.0));
  {
    AABB ref1[3];
    ref1[0] = OCTET_NPN;
    ref1[1] = OCTET_NPP;
    ref1[2] = BOTTOM_AABB;
    ref1[0].x2 = 16.0;
    ref1[1].x2 = 16.0;
    ref1[2].x2 = 16.0;

    for (i = 0; i < 3; ++i)
      {
	AABB *box = &ref1[i];

	box->x1 -= 8.0;
	box->y1 -= 8.0;
	box->z1 -= 8.0;
	box->x2 -= 8.0;
	box->y2 -= 8.0;
	box->z2 -= 8.0;
      }
    test (!decompose_AABBs (&test, ref1, 3));
  }
  test (region_equal_p (&face, &test));

  /* Right face.  */

  test (!region_select_face (&face, &stairs, AXIS_X, 8.0));
  {
    AABB ref1[3];
    ref1[0] = OCTET_PPP;
    ref1[1] = OCTET_PPN;
    ref1[2] = BOTTOM_AABB;
    ref1[0].x1 = 0.0;
    ref1[1].x1 = 0.0;
    ref1[2].x1 = 0.0;

    for (i = 0; i < 3; ++i)
      {
	AABB *box = &ref1[i];

	box->x1 -= 8.0;
	box->y1 -= 8.0;
	box->z1 -= 8.0;
	box->x2 -= 8.0;
	box->y2 -= 8.0;
	box->z2 -= 8.0;
      }
    test (!decompose_AABBs (&test, ref1, 3));
  }
  test (region_equal_p (&face, &test));

  /* Front face.  */

  test (!region_select_face (&face, &stairs, AXIS_Z, -8.0));
  {
    AABB ref1[2];
    ref1[0] = OCTET_NPN;
    ref1[1] = BOTTOM_AABB;
    ref1[0].z2 = 16.0;
    ref1[1].z2 = 16.0;

    for (i = 0; i < 2; ++i)
      {
	AABB *box = &ref1[i];

	box->x1 -= 8.0;
	box->y1 -= 8.0;
	box->z1 -= 8.0;
	box->x2 -= 8.0;
	box->y2 -= 8.0;
	box->z2 -= 8.0;
      }
    test (!decompose_AABBs (&test, ref1, 2));
  }
  test (region_equal_p (&face, &test));

  /* Rear face.  */
  test (!region_select_face (&face, &stairs, AXIS_Z, 8.0));
  reference.x1 = -8.0;
  reference.y1 = -8.0;
  reference.z1 = -8.0;
  reference.x2 = 8.0;
  reference.y2 = 8.0;
  reference.z2 = 8.0;
  test (!decompose_AABBs (&test, &reference, 1));
  test (region_equal_p (&face, &test));

  {
    AABB fence_post = {
      -0.125, -0.5, -0.125,
      0.125, 1.0, 0.125,
    };
    AABB fence_post_wanted = {
      -0.125, -0.5, -0.125,
      0.125, 0.5, 0.125,
    };

    test (!decompose_AABBs (&stairs, &fence_post, 1));
    test (!region_select_face (&face, &stairs, AXIS_Y, 0.5));
    test (!decompose_AABBs (&test, &fence_post_wanted, 1));
    test (region_equal_p (&test, &face));
  }

  region_release (&stairs);
  region_release (&face);
  region_release (&test);
}

static void
test_empty_region (void)
{
  struct cuboid_region rgn1, empty, rgn2;
  int size_1 = sizeof big_region_1 / sizeof (AABB);

  region_init (&rgn1);
  region_init (&empty);
  region_init (&rgn2);

  printf ("%s:\n", "test_empty_region");

  test (!decompose_AABBs (&rgn2, big_region_1, size_1));
  test (!region_op (&rgn1, &empty, &rgn2, OP_OR));
  test (region_equal_p (&rgn1, &rgn2));
  test (!region_op (&rgn1, &empty, &rgn2, OP_AND));
  test (region_equal_p (&rgn1, &empty) && region_empty_p (&rgn1));
  test (!region_op (&rgn1, &empty, &rgn2, OP_SUB));
  test (region_equal_p (&rgn1, &empty) && region_empty_p (&rgn1));
  test (!region_op (&rgn1, &rgn2, &empty, OP_SUB));
  test (region_equal_p (&rgn1, &rgn2));
  test (!region_op (&rgn1, &empty, &rgn2, OP_NEQ));
  test (region_equal_p (&rgn1, &rgn2));

  region_release (&rgn1);
  region_release (&empty);
  region_release (&rgn2);
}

int
main (int argc, char *argv[])
{
  test_AABB_to_rgn ();
  test_AABBs_to_rgn ();
  test_region_ops ();
  test_region_ops_1 ();
  test_region_optimization ();
  test_walk_AABBs ();
  test_shorthand_ops ();
  test_faces ();
  test_empty_region ();
  return 0;
}
