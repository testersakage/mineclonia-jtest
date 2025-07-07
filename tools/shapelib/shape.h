#define CHAR_BITS		8
#define UNIT_TYPE		double
#define MAX_EDGES_PER_AXIS	1023 /* 2^10 - 1.  */
#define E			1.0e-7
#define UINT_BITS		32
#define BITSET_SIZE(disp, x, y, z)				\
  ((((((x) << ((disp) + (disp)))				\
     + ((y) << (disp)) + (z)) + UINT_BITS - 1) / UINT_BITS))

#if __STDC_VERSION__ >= 199901L
#define RESTRICT restrict
#else /* __STDC_VERSION__ < 199901L */
#define RESTRICT
#endif /* __STDC_VERSION__ < 199901L */

struct cuboid_region
{
  /* Bitset recording vertex occupancy by AABBs.  */
  unsigned int *solids;

  /* Arrays of sorted edges along each axis.  Only X_EDGES points to a
     region of allocated memory; Y_EDGES and Z_EDGES are simply
     pointers to values at appropriate offsets from X_EDGES.  */
  UNIT_TYPE *x_edges;
  UNIT_TYPE *y_edges;
  UNIT_TYPE *z_edges;

  /* Number of elements occupied in those three arrays.  */
  int x_size;
  int y_size;
  int z_size;

  /* Size of bitset previously allocated, and the number of bits by
     which each component of a coordinate must be shifted to produce
     an index into the SOLIDS bitset.  */
  int b_size, b_disp;

  /* An array of six elements meant to hold statically allocated
     edges.  */
  UNIT_TYPE static_edges[6];
};

struct AABB
{
  UNIT_TYPE x1, y1, z1;
  UNIT_TYPE x2, y2, z2;
};

typedef struct AABB AABB;

#define OP_OR	1
#define OP_AND	2
#define OP_SUB	3
#define OP_NEQ	4
#define OP_BNA	5

#ifdef __STDC__
#define PROTO(proto) proto
#else /* !__STDC__ */
#define PROTO(proto) ()
#endif /* __STDC__ */

#if 4 < __GNUC__ + (5 <= __GNUC_MINOR__) && !defined __clang__
#define UNREACHABLE (__builtin_unreachable ())
#endif /* 4 < __GNUC__ + (5 <= __GNUC_MINOR__) && !defined __clang__ */
#ifndef UNREACHABLE
#define UNREACHABLE ((void) 0)
#endif /* !UNREACHABLE */

#define AXIS_X	0
#define AXIS_Y	1
#define AXIS_Z	2



#define AABB_VALID_P(aabb)			\
  (((aabb)->x1 < (aabb)->x2)			\
   && ((aabb)->y1 < (aabb)->y2)			\
   && ((aabb)->z1 < (aabb)->z2))

extern void region_init PROTO ((struct cuboid_region *));
extern void region_release PROTO ((struct cuboid_region *));
extern int region_copy PROTO ((struct cuboid_region *, struct cuboid_region *));
extern int decompose_AABBs PROTO ((struct cuboid_region *, AABB *, int));
extern int region_op PROTO ((struct cuboid_region *, struct cuboid_region *,
			     struct cuboid_region *, int));
extern int region_is_AABB PROTO ((struct cuboid_region *, UNIT_TYPE,
				  UNIT_TYPE, UNIT_TYPE));
extern int region_equal_p PROTO ((struct cuboid_region *,
				  struct cuboid_region *));
extern int region_intersect_p PROTO ((struct cuboid_region *,
				      struct cuboid_region *));
extern int region_contains_p PROTO ((struct cuboid_region *,
				     struct cuboid_region *));
extern int region_empty_p PROTO ((struct cuboid_region *));
extern int region_walk PROTO ((struct cuboid_region *, int (*) (AABB *, void *,
								void *),
			       void *, void *));
extern int region_simplify PROTO ((struct cuboid_region *,
				   struct cuboid_region *));

extern void region_init_from_AABB PROTO ((struct cuboid_region *, AABB *));
extern int region_intersect PROTO ((struct cuboid_region *,
				    struct cuboid_region *,
				    AABB *));
extern int region_subtract PROTO ((struct cuboid_region *,
				   struct cuboid_region *,
				   AABB *));
extern int region_union PROTO ((struct cuboid_region *, struct cuboid_region *,
				AABB *));
extern int region_select_face PROTO ((struct cuboid_region *, struct cuboid_region *,
				      int, UNIT_TYPE));

/* Local Variables: */
/* c-noise-macro-names: ("PROTO") */
/* End: */
