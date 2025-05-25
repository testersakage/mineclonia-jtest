/* Region data structure.

   A set of AABBs is decomposed into a sorted set of edges along each
   axis, and each vertex occupied by an AABB's min_pos or between the
   same and its max_pos is marked as such.  */

#include <alloca.h>
#include <assert.h>
#include <stddef.h>
#include <string.h>
#include <stdlib.h>
#include "shape.h"

#define MIN(x, y) ((x) < (y) ? (x) : (y))
#define MAX(x, y) ((x) > (y) ? (x) : (y))



/* Shape initialization.  */

/* Initialize the region REGION.  This must be called before REGION
   becomes the source or destination of any region operation.  */

void
region_init (region)
     struct cuboid_region *region;
{
  region->solids = NULL;
  region->x_size = 0;
  region->y_size = 0;
  region->z_size = 0;
  region->b_size = 0;
}

/* Release resources allocated in the region REGION.  */

void
region_release (region)
     struct cuboid_region *region;
{
  if (region->solids)
    free (region->solids);
  region->solids = NULL;
  region->x_size = 0;
  region->y_size = 0;
  region->z_size = 0;
  region->b_size = 0;
}

static int
resize_solids (region, size)
     struct cuboid_region *region;
     int size;
{
  int size_bytes = size * sizeof *region->solids;

  if (region->b_size < size)
    {
      unsigned int *solids;
      solids = realloc (region->solids, size_bytes);
      if (!solids)
	return 1;
      region->solids = solids;
    }

  region->b_size = size;
  memset (region->solids, 0, size_bytes);
  return 0;
}

/* Copy the region SRC into DST.  Value is 1 on failure.  */

int
region_copy (dst, src)
     struct cuboid_region *RESTRICT dst;
     struct cuboid_region *src;
{
  int total_size;

  if (resize_solids (dst, BITSET_SIZE (src->x_size,
				       src->y_size,
				       src->z_size)))
    return 1;

  dst->x_size = src->x_size;
  dst->y_size = src->y_size;
  dst->z_size = src->z_size;
  total_size = dst->b_size * sizeof *dst->solids;
  memcpy (dst->solids, src->solids, total_size);
  memcpy (dst->x_edges, src->x_edges, sizeof src->x_edges);
  memcpy (dst->y_edges, src->y_edges, sizeof src->y_edges);
  memcpy (dst->z_edges, src->z_edges, sizeof src->z_edges);
  return 0;
}



/* Shape decomposition.  */

/* Sort an array of edges EDGES with SIZE elements in place, removing
   duplicates.  */

static int
edge_sort (edges, size)
     UNIT_TYPE *edges;
     int size;
{
  int i, k = 0;

  for (i = 0; i < size; ++i)
    {
      UNIT_TYPE edge = edges[i];
      int j = i - 1;

      while (j >= 0 && edges[j] > edge)
	{
	  edges[j + 1] = edges[j];
	  j--;
	}

      edges[j + 1] = edge;
    }

  for (i = 0; i < size; ++i)
    {
      if (!k || edges[i] != edges[k - 1])
	edges[k++] = edges[i];
    }

  return k;
}

/* Return a pointer to the first element in ARRAY of size NMEMB equal
   to or lesser than VALUE, or NULL on failure.  */

static UNIT_TYPE *
bisect (edges, nmemb, value)
     UNIT_TYPE *edges;
     int nmemb;
     UNIT_TYPE value;
{
  int low = 0, high = nmemb - 1;

  if (nmemb)
    {
      while (low != high)
	{
	  int mid = (low + high) / 2;

	  if (edges[mid] < value)
	    low = mid + 1;
	  else
	    high = mid;
	}

      if (edges[low] > value)
	return low > 0 ? edges + low - 1 : NULL;

      return edges + low;
    }

  return NULL;
}

#define XINDEX(x, base)				\
  (((x) - (base)) * EDGES_PER_AXIS * EDGES_PER_AXIS)
#define YINDEX(y, base)				\
  (((y) - (base)) * EDGES_PER_AXIS)
#define ZINDEX(z, base) ((z) - (base))

#define IS_OCCUPIED_P(rgn, idx)					\
  (((rgn)->solids[(idx) / UINT_BITS]				\
    & (1 << ((idx) % UINT_BITS))) != 0)				\

#define MARK_OCCUPIED(rgn, idx)						\
  ((rgn)->solids[(idx) / UINT_BITS] |= (1 << ((idx) % UINT_BITS)))	\

/* Decompose an array of N_AABBS bounding boxes into a cuboid region
   structure.  Value is 1 on failure.  */

int
decompose_AABBs (region, aabbs, n_aabbs)
     struct cuboid_region *region;
     int n_aabbs;
     AABB *aabbs;
{
  UNIT_TYPE *x_edges;
  UNIT_TYPE *y_edges;
  UNIT_TYPE *z_edges;
  int i, x_count, y_count, z_count;
  AABB *aabb = aabbs;

  /* Build arrays of edges.  */
  x_edges = alloca (n_aabbs * 2 * sizeof *x_edges);
  y_edges = alloca (n_aabbs * 2 * sizeof *y_edges);
  z_edges = alloca (n_aabbs * 2 * sizeof *z_edges);

  for (i = 0; i < n_aabbs * 2; i += 2)
    {
      assert (AABB_VALID_P (aabb));
      x_edges[i] = aabb->x1;
      x_edges[i + 1] = aabb->x2;
      y_edges[i] = aabb->y1;
      y_edges[i + 1] = aabb->y2;
      z_edges[i] = aabb->z1;
      z_edges[i + 1] = aabb->z2;
      aabb++;
    }

  /* Sort these edges, removing duplicates.  */
  x_count = edge_sort (x_edges, i);
  y_count = edge_sort (y_edges, i);
  z_count = edge_sort (z_edges, i);

  if (x_count > EDGES_PER_AXIS
      || y_count > EDGES_PER_AXIS
      || z_count > EDGES_PER_AXIS)
    return 1;

  /* Copy these into the region.  */
  memcpy (&region->x_edges, x_edges, x_count * sizeof (*x_edges));
  memcpy (&region->y_edges, y_edges, y_count * sizeof (*y_edges));
  memcpy (&region->z_edges, z_edges, z_count * sizeof (*z_edges));
  region->x_size = x_count;
  region->y_size = y_count;
  region->z_size = z_count;

  /* Allocate or resize solids array.  */
  if (resize_solids (region, BITSET_SIZE (x_count, y_count, z_count)))
    return 1;

  /* Mark AABBs.  */
  aabb = aabbs;
  while (aabb != aabbs + n_aabbs)
    {
      UNIT_TYPE *x1 = bisect (region->x_edges, x_count, aabb->x1);
      UNIT_TYPE *y1 = bisect (region->y_edges, y_count, aabb->y1);
      UNIT_TYPE *z1 = bisect (region->z_edges, z_count, aabb->z1);
      UNIT_TYPE *x2 = bisect (region->x_edges, x_count, aabb->x2);
      UNIT_TYPE *y2 = bisect (region->y_edges, y_count, aabb->y2);
      UNIT_TYPE *z2 = bisect (region->z_edges, z_count, aabb->z2);
      UNIT_TYPE *x, *y, *z;

      assert (*x1 == aabb->x1 && *y1 == aabb->y1 && *z1 == aabb->z1
	      && *x2 == aabb->x2 && *y2 == aabb->y2 && *z2 == aabb->z2
	      && x2 > x1 && y2 > y1 && z2 > z1);

      /* Every vertex between (X1, Y1, Z1) and (X2, Y2, Z2) must also
	 be marked in addition to the origin position itself.  */
      for (x = x1; x < x2; ++x)
	{
	  for (y = y1; y < y2; ++y)
	    {
	      for (z = z1; z < z2; ++z)
		{
		  int index = (XINDEX (x, region->x_edges)
			       + YINDEX (y, region->y_edges)
			       + ZINDEX (z, region->z_edges));
		  MARK_OCCUPIED (region, index);
		}
	    }
	}
      aabb++;
    }

  return 0;
}



/* Shape operations.  */

static int
merge_edge_list (l, r, l_size, r_size, output, output_size)
     UNIT_TYPE *l;
     UNIT_TYPE *r;
     int l_size;
     int r_size;
     UNIT_TYPE *RESTRICT output;
     int *output_size;
{
  UNIT_TYPE *l_max = l + l_size;
  UNIT_TYPE *r_max = r + r_size;
  int size = 0;
  UNIT_TYPE next = MIN (*l, *r);

  while (l != l_max || r != r_max)
    {
      UNIT_TYPE *l_old = l;
      UNIT_TYPE *r_old = r;

      if (size != EDGES_PER_AXIS)
	output[size++] = next;
      else
	return 1;

      if (l != l_max && (r_old == r_max || *l_old <= *r_old))
	l++;

      if (r != r_max && (l_old == l_max || *r_old <= *l_old))
	r++;

      /* Select the next value or break.  */
      if (l != l_max && r != r_max)
	next = MIN (*l, *r);
      else if (l != l_max)
	next = *l;
      else if (r != r_max)
	next = *r;
    }

  *output_size = size;
  return 0;
}

/* Return the values that should provide the left and right hand
   sides of a boolean operation in *L_DOM and *R_DOM, from a set
   of arrays defined by L_BASE, R_BASE, L_MAX, and R_MAX, and an
   active set of values, L and R.  */

static void
get_dominating_values (l_dom, r_dom, l, r, l_base, r_base, l_max, r_max)
     UNIT_TYPE **l_dom;
     UNIT_TYPE **r_dom;
     UNIT_TYPE *l;
     UNIT_TYPE *r;
     UNIT_TYPE *l_base;
     UNIT_TYPE *r_base;
     UNIT_TYPE *l_max;
     UNIT_TYPE *r_max;
{
  UNIT_TYPE *ldom, *rdom;

  if (l == l_max)
    {
      ldom = NULL;
      rdom = (r == r_max ? NULL : r);
    }
  else if (r == r_max)
    {
      ldom = (l == l_max ? NULL : l);
      rdom = NULL;
    }
  else if (*l < *r)
    {
      ldom = l;
      rdom = r == r_base ? NULL : r - 1;
      assert (!rdom || *rdom < *ldom);
    }
  else if (*r < *l)
    {
      ldom = l == l_base ? NULL : l - 1;
      rdom = r;
      assert (!ldom || *ldom < *rdom);
    }
  else
    {
      ldom = l;
      rdom = r;
    }

  *l_dom = ldom;
  *r_dom = rdom;
}

#define BOOLEAN_OP(op, l, r)				\
  (((op) == OP_OR ? ((l) || (r))			\
    : ((op) == OP_AND ? ((l) && (r))			\
       : ((op) == OP_SUB ? ((l) && !(r))		\
	  : ((op) == OP_NEQ ? ((l) != (r))		\
	     : (UNREACHABLE, 0))))))

/* Apply the boolean operation OP to the regions L and R, producing a
   new region in NEW, which should already have been cleared.  Value
   is non-zero on failure.  */

int
region_op (new, l, r, op)
     struct cuboid_region *RESTRICT new;
     struct cuboid_region *l;
     struct cuboid_region *r;
     int op;
{
  int status = 0;
  UNIT_TYPE *lx = l->x_edges, *ly = l->y_edges, *lz = l->z_edges;
  UNIT_TYPE *rx = r->x_edges, *ry = r->y_edges, *rz = r->z_edges;
  UNIT_TYPE *x = new->x_edges, *y = new->y_edges, *z = new->z_edges;
  int l_on, r_on;
  UNIT_TYPE *lx_max, *rx_max;
#ifndef NDEBUG
  UNIT_TYPE x_next;
#endif /* !NDEBUG */

  /* Punt if empty.  */
  if (!l->x_size || !l->y_size || !l->z_size)
    {
      if (op == OP_OR || op == OP_NEQ)
	return region_copy (new, r);

      goto clear;
    }
  else if (!r->x_size || !r->y_size || !r->z_size)
    {
      if (op == OP_OR || op == OP_NEQ || op == OP_SUB)
	return region_copy (new, l);

      goto clear;
    }

  /* Merge edge lists.  */
  status |= merge_edge_list (lx, rx, l->x_size, r->x_size, x,
			     &new->x_size);
  status |= merge_edge_list (ly, ry, l->y_size, r->y_size, y,
			     &new->y_size);
  status |= merge_edge_list (lz, rz, l->z_size, r->z_size, z,
			     &new->z_size);
  if (status)
    return status;

  /* Allocate or resize solids array.  */
  if (resize_solids (new, BITSET_SIZE (new->x_size,
				       new->y_size,
				       new->z_size)))
    return 1;

  /* Apply the boolean operation to every cuboid in the old and new
     regions.  Every vertex in the combined list is also the origin of
     a cuboid if it is:

  	a) marked as such in L or R.

        b) or, between a cuboid that is occupied in either shape and
	   the next vertex in the shape in which it is marked.  */

  lx_max = l->x_edges + l->x_size;
  rx_max = r->x_edges + r->x_size;
#ifndef NDEBUG
  x_next = MIN (*lx, *rx);
#endif /* !NDEBUG */

  while (lx != lx_max || rx != rx_max)
    {
      UNIT_TYPE *ly = l->y_edges;
      UNIT_TYPE *ry = r->y_edges;
      UNIT_TYPE *ly_max = l->y_edges + l->y_size;
      UNIT_TYPE *ry_max = r->y_edges + r->y_size;
      UNIT_TYPE *y = new->y_edges;
#ifndef NDEBUG
      UNIT_TYPE y_next = MIN (*ly, *ry);
#endif /* !NDEBUG */
      UNIT_TYPE *lx_old = lx;
      UNIT_TYPE *rx_old = rx;
      UNIT_TYPE *lx_dom, *rx_dom;
      int lx_index;
      int rx_index;
      int x_index;

      /* An axis's ``dominating'' values are those providing the
	 state of the LHS and RHS respectively.  Each is the
	 lesser value itself if its side provides it, or the
	 previous value, which should precede the LHS
	 numerically.  */
      get_dominating_values (&lx_dom, &rx_dom, lx, rx, l->x_edges,
			     r->x_edges, lx_max, rx_max);
      if (lx_dom)
	lx_index = XINDEX (lx_dom, l->x_edges);
      if (rx_dom)
	rx_index = XINDEX (rx_dom, r->x_edges);
      x_index = XINDEX (x, new->x_edges);
      assert (x < new->x_edges + new->x_size && x_next == *x);

      while (ly != ly_max || ry != ry_max)
	{
	  UNIT_TYPE *lz = l->z_edges;
	  UNIT_TYPE *rz = r->z_edges;
	  UNIT_TYPE *lz_max = l->z_edges + l->z_size;
	  UNIT_TYPE *rz_max = r->z_edges + r->z_size;
	  UNIT_TYPE *z = new->z_edges;
#ifndef NDEBUG
	  UNIT_TYPE z_next = MIN (*lz, *rz);
#endif /* !NDEBUG */
	  UNIT_TYPE *ly_old = ly;
	  UNIT_TYPE *ry_old = ry;
	  UNIT_TYPE *ly_dom, *ry_dom;
	  int ly_index;
	  int ry_index;
	  int y_index;

	  get_dominating_values (&ly_dom, &ry_dom, ly, ry, l->y_edges,
				 r->y_edges, ly_max, ry_max);
	  if (ly_dom)
	    ly_index = YINDEX (ly_dom, l->y_edges);
	  if (ry_dom)
	    ry_index = YINDEX (ry_dom, r->y_edges);
	  y_index = YINDEX (y, new->y_edges);
	  assert (y < new->y_edges + new->y_size && y_next == *y);

	  while (lz != lz_max || rz != rz_max)
	    {
	      UNIT_TYPE *lz_old = lz;
	      UNIT_TYPE *rz_old = rz;
	      UNIT_TYPE *lz_dom, *rz_dom;
	      int lz_index;
	      int rz_index;
	      int z_index;

	      get_dominating_values (&lz_dom, &rz_dom, lz, rz, l->z_edges,
				     r->z_edges, lz_max, rz_max);
	      if (lz_dom)
		lz_index = ZINDEX (lz_dom, l->z_edges);
	      if (rz_dom)
		rz_index = ZINDEX (rz_dom, r->z_edges);
	      z_index = ZINDEX (z, new->z_edges);
	      assert (z < new->z_edges + new->z_size && z_next == *z);

	      l_on = (lx_dom && ly_dom && lz_dom
		      && IS_OCCUPIED_P (l, lx_index + ly_index + lz_index));
	      r_on = (rx_dom && ry_dom && rz_dom
		      && IS_OCCUPIED_P (r, rx_index + ry_index + rz_index));

	      /* Mark this vertex as occupied if the boolean operation
		 succeeds.  */
	      if (BOOLEAN_OP (op, l_on, r_on))
		MARK_OCCUPIED (new, x_index + y_index + z_index);

	      /* Decide which value to increment and adjust l_on/r_on
		 accordingly.  */
	      if (lz != lz_max && (rz_old == rz_max || *lz_old <= *rz_old))
		lz++;
	      if (rz != rz_max && (lz_old == lz_max || *rz_old <= *lz_old))
		rz++;

#ifndef NDEBUG
	      if (rz != rz_max && lz != lz_max)
		z_next = MIN (*rz, *lz);
	      else if (rz != rz_max)
		z_next = *rz;
	      else if (lz != lz_max)
		z_next = *lz;
#endif /* !NDEBUG */
	      z++;
	    }

	  /* Decide which value to increment and adjust l_on/r_on
	     accordingly.  */
	  if (ly != ly_max && (ry_old == ry_max || *ly_old <= *ry_old))
	    ly++;
	  if (ry != ry_max && (ly_old == ly_max || *ry_old <= *ly_old))
	    ry++;

#ifndef NDEBUG
	  if (ry != ry_max && ly != ly_max)
	    y_next = MIN (*ry, *ly);
	  else if (ry != ry_max)
	    y_next = *ry;
	  else if (ly != ly_max)
	    y_next = *ly;
#endif /* !NDEBUG */
	  y++;
	}

      /* Decide which value to increment and adjust l_on/r_on
	 accordingly.  */
      if (lx != lx_max && (rx_old == rx_max || *lx_old <= *rx_old))
	lx++;
      if (rx != rx_max && (lx_old == lx_max || *rx_old <= *lx_old))
	rx++;

#ifndef NDEBUG
      if (rx != rx_max && lx != lx_max)
	x_next = MIN (*rx, *lx);
      else if (rx != rx_max)
	x_next = *rx;
      else if (lx != lx_max)
	x_next = *lx;
#endif /* !NDEBUG */
      x++;
    }

  return 0;

 clear:
  /* One of the operands is empty and the operation is such that the
     output must be cleared.  */
  if (!resize_solids (new, 0, 0, 0))
    {
      new->x_size = 0;
      new->y_size = 0;
      new->z_size = 0;
      return 0;
    }

  return 1;
}

/* Return whether (X, Y, Z) constitutes the origin of an AABB in
   REGION.  */

int
region_is_AABB (region, x, y, z)
     struct cuboid_region *region;
     UNIT_TYPE x;
     UNIT_TYPE y;
     UNIT_TYPE z;
{
  UNIT_TYPE *px = bisect (region->x_edges, region->x_size, x);
  UNIT_TYPE *py = bisect (region->y_edges, region->y_size, y);
  UNIT_TYPE *pz = bisect (region->z_edges, region->z_size, z);

  return (px && py && pz
	  && (*px == x && *py == y && *pz == z)
	  && IS_OCCUPIED_P (region, (XINDEX (px, region->x_edges)
				     + YINDEX (py, region->y_edges)
				     + ZINDEX (pz, region->z_edges))));
}

/* Return whether the boolean operation OP evaluates to true for
   all intersections between L and R.  */

static int
region_evaluate (l, r, op)
     struct cuboid_region *l;
     struct cuboid_region *r;
     int op;
{
  int l_on, r_on;
  UNIT_TYPE *lx = l->x_edges;
  UNIT_TYPE *rx = r->x_edges;
  UNIT_TYPE *lx_max, *rx_max;
  UNIT_TYPE *ly_max, *ry_max;
  UNIT_TYPE *lz_max, *rz_max;

  lx_max = l->x_edges + l->x_size;
  rx_max = r->x_edges + r->x_size;
  ly_max = l->y_edges + l->y_size;
  ry_max = r->y_edges + r->y_size;
  lz_max = l->z_edges + l->z_size;
  rz_max = r->z_edges + r->z_size;

  /* Punt if empty.  */
  if (!l->x_size || !l->y_size || !l->z_size)
    return BOOLEAN_OP (op, 0, !region_empty_p (r));
  else if (!r->x_size || !r->y_size || !r->z_size)
    return BOOLEAN_OP (op, !region_empty_p (l), 0);

  while (lx != lx_max || rx != rx_max)
    {
      UNIT_TYPE *ly = l->y_edges;
      UNIT_TYPE *ry = r->y_edges;
      UNIT_TYPE *lx_old = lx;
      UNIT_TYPE *rx_old = rx;
      UNIT_TYPE *lx_dom, *rx_dom;
      int lx_index;
      int rx_index;

      /* An axis's ``dominating'' values are those providing the
	 state of the LHS and RHS respectively.  Each is the
	 lesser value itself if its side provides it, or the
	 previous value, which should precede the LHS
	 numerically.  */
      get_dominating_values (&lx_dom, &rx_dom, lx, rx, l->x_edges,
			     r->x_edges, lx_max, rx_max);
      if (lx_dom)
	lx_index = XINDEX (lx_dom, l->x_edges);
      if (rx_dom)
	rx_index = XINDEX (rx_dom, r->x_edges);

      while (ly != ly_max || ry != ry_max)
	{
	  UNIT_TYPE *lz = l->z_edges;
	  UNIT_TYPE *rz = r->z_edges;
	  UNIT_TYPE *ly_old = ly;
	  UNIT_TYPE *ry_old = ry;
	  UNIT_TYPE *ly_dom, *ry_dom;
	  int ly_index;
	  int ry_index;

	  get_dominating_values (&ly_dom, &ry_dom, ly, ry, l->y_edges,
				 r->y_edges, ly_max, ry_max);
	  if (ly_dom)
	    ly_index = YINDEX (ly_dom, l->y_edges);
	  if (ry_dom)
	    ry_index = YINDEX (ry_dom, r->y_edges);

	  while (lz != lz_max || rz != rz_max)
	    {
	      UNIT_TYPE *lz_old = lz;
	      UNIT_TYPE *rz_old = rz;
	      UNIT_TYPE *lz_dom, *rz_dom;
	      int lz_index, rz_index;

	      get_dominating_values (&lz_dom, &rz_dom, lz, rz, l->z_edges,
				     r->z_edges, lz_max, rz_max);
	      if (lz_dom)
		lz_index = ZINDEX (lz_dom, l->z_edges);
	      if (rz_dom)
		rz_index = ZINDEX (rz_dom, r->z_edges);

	      l_on = (lx_dom && ly_dom && lz_dom
		      && IS_OCCUPIED_P (l, lx_index + ly_index + lz_index));
	      r_on = (rx_dom && ry_dom && rz_dom
		      && IS_OCCUPIED_P (r, rx_index + ry_index + rz_index));

	      /* Evaluate this boolean operation.  */
	      if (BOOLEAN_OP (op, l_on, r_on))
		return 1;

	      if (lz != lz_max && (rz_old == rz_max || *lz_old <= *rz_old))
		lz++;

	      if (rz != rz_max && (lz_old == lz_max || *rz_old <= *lz_old))
		rz++;
	    }

	  /* Decide which value to increment and adjust l_on/r_on
	     accordingly.  */

	  if (ly != ly_max && (ry_old == ry_max || *ly_old <= *ry_old))
	    ly++;

	  if (ry != ry_max && (ly_old == ly_max || *ry_old <= *ly_old))
	    ry++;
	}

      /* Decide which value to increment and adjust l_on/r_on
	 accordingly.  */
      if (lx != lx_max && (rx_old == rx_max || *lx_old <= *rx_old))
	lx++;
      if (rx != rx_max && (lx_old == lx_max || *rx_old <= *lx_old))
	rx++;
    }

  return 0;
}

/* Return whether L is equal to R.  */

int
region_equal_p (l, r)
     struct cuboid_region *l;
     struct cuboid_region *r;
{
  return (l == r || !region_evaluate (l, r, OP_NEQ));
}

/* Return whether L intersects with R.  */

int
region_intersect_p (l, r)
     struct cuboid_region *l;
     struct cuboid_region *r;
{
  return (l == r || region_evaluate (l, r, OP_AND));
}

static int
any_occupied_p (region)
     struct cuboid_region *region;
{
  UNIT_TYPE *x, *y, *z;
  UNIT_TYPE *x_max = region->x_edges + region->x_size;
  UNIT_TYPE *y_max = region->y_edges + region->y_size;
  UNIT_TYPE *z_max = region->z_edges + region->z_size;

  for (x = region->x_edges; x < x_max; ++x)
    {
      int x_index = XINDEX (x, region->x_edges);

      for (y = region->y_edges; y < y_max; ++y)
	{
	  int y_index = YINDEX (y, region->y_edges);

	  for (z = region->z_edges; z < z_max; ++z)
	    {
	      int z_index = YINDEX (z, region->z_edges);

	      if (IS_OCCUPIED_P (region, x_index + y_index + z_index))
		return 1;
	    }
	}
    }

  return 0;
}

/* Return whether REGION is empty.  */

int
region_empty_p (region)
     struct cuboid_region *region;
{
  return (!region->x_size || !region->y_size
	  || !region->z_size || !any_occupied_p (region));
}



/* Region traversal.  */

typedef struct
{
  /* Lower extent of a section of a region's edge arrays.  */
  UNIT_TYPE *x1, *y1, *z1;

  /* Upper extent of the same.  */
  UNIT_TYPE *x2, *y2, *z2;
} IndexRegion;

struct iter_queue
{
  /* Pointer to fill and read pointers.  */
  IndexRegion *fetch, *fill;

  /* Queue data.  */
  IndexRegion *data;

  /* Size of the queue.  */
  int n_elements;
};

static void
init_queue (queue)
     struct iter_queue *queue;
{
  queue->fetch = queue->fill = queue->data = NULL;
  queue->n_elements = 0;
}

static void
release_queue (queue)
     struct iter_queue *queue;
{
  if (queue->data)
    free (queue->data);
}

static IndexRegion *
queue_read (queue)
     struct iter_queue *queue;
{
  IndexRegion *rgn;

  if (!queue->n_elements || queue->fetch == queue->fill)
    return NULL;

  rgn = queue->fetch;
  queue->fetch = rgn + 1;
  if (queue->fetch == queue->data + queue->n_elements)
    queue->fetch = queue->data;
  return rgn;
}

#define DEFAULT_QUEUE_SIZE 32
#define QUEUE_FILL_NEXT(queue)					\
  (((queue)->fill + 1 == (queue)->data + (queue)->n_elements)	\
   ? (queue)->data : (queue)->fill + 1)

static int
queue_insert (queue, region)
     struct iter_queue *queue;
     IndexRegion *region;
{
  IndexRegion *next = QUEUE_FILL_NEXT (queue);

  /* If the queue is full, expand it.  */
  if (queue->n_elements == 0 || next == queue->fetch)
    {
      int fetch_offset = queue->fetch - queue->data;
      int fill_offset = queue->fill - queue->data;
      int size = queue->n_elements;
      int new_size = MAX (DEFAULT_QUEUE_SIZE, size * 2);
      IndexRegion *new_data
	= realloc (queue->data, new_size * sizeof (IndexRegion));
      if (!new_data)
	return 1;

      /* Move the fill pointer and any data that may sit behind it to
	 the front of the array.  */
      if (fetch_offset > fill_offset)
	{
	  int i;

	  for (i = 0; i < fill_offset; ++i)
	    new_data[size + i] = new_data[i];
	  fill_offset = size + i;
	}
      queue->data = new_data;
      queue->fetch = new_data + fetch_offset;
      queue->fill = new_data + fill_offset;
      queue->n_elements = new_size;
      next = QUEUE_FILL_NEXT (queue);
    }

  assert (region->x1 < region->x2);
  assert (region->y1 < region->y2);
  assert (region->z1 < region->z2);
  assert (queue->fill < queue->fill + queue->n_elements);
  *queue->fill = *region;
  queue->fill = next;
  return 0;
}

/* Within that part of REGION which is defined by PART, locate the
   first cuboid along the X, Y, and Z axes, and return the same in
   *CUBOID and that area of PART which is certain not to contain any
   cuboids in *EXPLORED.  Value is 0 if no cuboid exists in this
   region.  */

int
find_cuboid (region, part, cuboid, explored)
     struct cuboid_region *region;
     IndexRegion *part;
     IndexRegion *cuboid;
     IndexRegion *explored;
{
  UNIT_TYPE *x, *y, *z;
  int xindex, yindex, zindex;

  for (x = part->x1; x < part->x2; ++x)
    {
      xindex = XINDEX (x, region->x_edges);
      for (y = part->y1; y < part->y2; ++y)
	{
	  yindex = YINDEX (y, region->y_edges);
	  for (z = part->z1; z < part->z2; ++z)
	    {
	      zindex = ZINDEX (z, region->z_edges);

	      if (IS_OCCUPIED_P (region, xindex + yindex + zindex))
		/* (X Y Z) constitutes the origin of a cuboid.
		   Establish its bounds and return them.  */
		goto identified;
	    }
	}
    }

  /* Nothing was located.  */
  return 0;

 identified:
  explored->x1 = part->x1;
  explored->y1 = part->y1;
  explored->x1 = part->x1;
  explored->x2 = x;
  explored->y2 = y;
  explored->z2 = z;
  cuboid->x1 = x;
  cuboid->y1 = y;
  cuboid->z1 = z;

  {
    UNIT_TYPE *x_end, *y_end, *z_end;

    for (x_end = x + 1; x_end < part->x2; ++x_end)
      {
	xindex = XINDEX (x_end, region->x_edges);
	if (!IS_OCCUPIED_P (region, xindex + yindex + zindex))
	  break;
      }

    /* X is the outer extent of this cuboid on the X axis.  Establish
       how far it extends along the Y axis.  */

    for (y_end = y + 1; y_end < part->y2; ++y_end)
      {
	UNIT_TYPE *x_test;

	yindex = YINDEX (y_end, region->y_edges);
	for (x_test = x; x_test < x_end; ++x_test)
	  {
	    xindex = XINDEX (x_test, region->x_edges);
	    if (!IS_OCCUPIED_P (region, xindex + yindex + zindex))
	      goto y_set;
	  }
      }

  y_set:
    /* Y is the outer extent of this cuboid on the Y axis.  Verify how
       far it extends along the Z axis.  */

    for (z_end = z + 1; z_end < part->z2; ++z_end)
      {
	UNIT_TYPE *y_test;

	zindex = ZINDEX (z_end, region->z_edges);
	for (y_test = y; y_test < y_end; ++y_test)
	  {
	    UNIT_TYPE *x_test;

	    yindex = YINDEX (y_test, region->y_edges);

	    for (x_test = x; x_test < x_end; ++x_test)
	      {
		xindex = XINDEX (x_test, region->x_edges);
		if (!IS_OCCUPIED_P (region, xindex + yindex + zindex))
		  goto z_set;
	      }
	  }
      }

  z_set:
    cuboid->x2 = x_end;
    cuboid->y2 = y_end;
    cuboid->z2 = z_end;

    /* This partly amounts to an assertion of the validity of every
       region in that every cuboid must be terminated by an unmarked
       edge.  */
    assert (cuboid->x2 > cuboid->x1
	    && cuboid->y2 > cuboid->y1
	    && cuboid->z2 > cuboid->z1);
    assert (cuboid->x2 <= part->x2
	    && cuboid->y2 <= part->y2
	    && cuboid->z2 <= part->z2);
  }

  return 1;
}

/* Walk REGION, calling FN with every AABB defined within and DATA and
   DATA1, till FN returns non-zero (whereupon 1 is returned) or the
   region is completely traversed and zero is returned.  */

int
region_walk (region, fn, data, data1)
     struct cuboid_region *region;
     int (*fn) PROTO ((AABB *, void *, void *));
     void *data;
     void *data1;
{
  UNIT_TYPE *x_max = region->x_edges + region->x_size;
  UNIT_TYPE *y_max = region->y_edges + region->y_size;
  UNIT_TYPE *z_max = region->z_edges + region->z_size;
  struct iter_queue queue;
  IndexRegion *next, initial;

  if (!region->x_size || !region->y_size || !region->z_size)
    return 0;

  init_queue (&queue);
  initial.x1 = region->x_edges;
  initial.y1 = region->y_edges;
  initial.z1 = region->z_edges;
  initial.x2 = x_max - 1;
  initial.y2 = y_max - 1;
  initial.z2 = z_max - 1;
  queue_insert (&queue, &initial);

  while ((next = queue_read (&queue)))
    {
      /* Proceeding from the origin of this rect, try to locate a
	 contiguous cuboid along the XYZ, YXZ, or ZXY axes, and
	 enqueue the remainder.  */
      IndexRegion cuboid, explored;

      if (find_cuboid (region, next, &cuboid, &explored))
	{
	  AABB aabb;
	  IndexRegion current = *next;
	  IndexRegion pending = current;

	  aabb.x1 = *cuboid.x1;
	  aabb.x2 = *cuboid.x2;
	  aabb.y1 = *cuboid.y1;
	  aabb.y2 = *cuboid.y2;
	  aabb.z1 = *cuboid.z1;
	  aabb.z2 = *cuboid.z2;
	  if ((*fn) (&aabb, data, data1))
	    return 1;

	  /* Subtract cuboid from next.  WARNING: queue_insert is
	     liable to invalidate NEXT.  */

	  /* Lengthwise segments.  */

	  if (cuboid.x1 > current.x1)
	    {
	      pending.x2 = cuboid.x1;
	      queue_insert (&queue, &pending);
	    }

	  if (cuboid.x2 < current.x2)
	    {
	      pending.x1 = cuboid.x2;
	      pending.x2 = current.x2;
	      queue_insert (&queue, &pending);
	    }

	  pending.x1 = cuboid.x1;
	  pending.x2 = cuboid.x2;

	  /* Vertical segments.  */

	  if (cuboid.y1 > current.y1)
	    {
	      pending.y2 = cuboid.y1;
	      queue_insert (&queue, &pending);
	    }

	  if (cuboid.y2 < current.y2)
	    {
	      pending.y1 = cuboid.y2;
	      pending.y2 = current.y2;
	      queue_insert (&queue, &pending);
	    }

	  pending.y1 = cuboid.y1;
	  pending.y2 = cuboid.y2;

	  /* Depthwise segments.  */

	  if (cuboid.z1 > current.z1)
	    {
	      pending.z2 = cuboid.z1;
	      queue_insert (&queue, &pending);
	    }

	  if (cuboid.z2 < current.z2)
	    {
	      pending.z1 = cuboid.z2;
	      pending.z2 = current.z2;
	      queue_insert (&queue, &pending);
	    }
	}
    }

  release_queue (&queue);
  return 0;
}



/* Region simplification.  */

/* Return whether the edge at EDGE is redundant with respect to
   the axes defined by OTHER_0 and OTHER_1.  */

static int
edge_redundant_p (region, edge, base, other_0, other_0_end,
		  other_1, other_1_end, index_scale,
		  index_scale_0, index_scale_1)
     struct cuboid_region *region;
     UNIT_TYPE *edge;
     UNIT_TYPE *base;
     UNIT_TYPE *other_0;
     UNIT_TYPE *other_0_end;
     UNIT_TYPE *other_1;
     UNIT_TYPE *other_1_end;
     int index_scale;
     int index_scale_0;
     int index_scale_1;
{
  int x_pos = (edge - base);
  int idx = x_pos * index_scale;
  UNIT_TYPE *p0;

  for (p0 = other_0; p0 != other_0_end; ++p0)
    {
      int y_pos = p0 - other_0;
      int idx_1 = y_pos * index_scale_0;
      UNIT_TYPE *p1;

      for (p1 = other_1; p1 != other_1_end; ++p1)
	{
	  int z_pos = p1 - other_1;
	  int idx_2 = z_pos * index_scale_1;
	  int index = idx + idx_1 + idx_2;
	  int state = IS_OCCUPIED_P (region, index);
	  int prev_state = 0;

	  /* This edge must not appear in an on-transition or an
	     off-transition.  That is to say, for every vertex
	     intersecting this edge the preceding position on its axis
	     must be identical to the status of the said vertex.  */
	  if (x_pos)
	    {
	      int index_prev = (idx - index_scale) + idx_1 + idx_2;
	      assert (index_prev >= 0);
	      prev_state = IS_OCCUPIED_P (region, index_prev);
	    }

	  if (prev_state != state)
	    return 0;
	}
    }

  return 1;
}

#define Z_SCALE 1
#define Y_SCALE (EDGES_PER_AXIS)
#define X_SCALE ((EDGES_PER_AXIS) * (EDGES_PER_AXIS))

/* Optimize a region REGION, storing the result in DEST.  A redundant
   edge is an edge along one axis whose presence does not affect the
   values of any intersecting axes.  Proceed by creating a new region
   in DEST without the redundant edges in SRC.  */

int
region_simplify (dest, region)
     struct cuboid_region *RESTRICT dest;
     struct cuboid_region *region;
{
  UNIT_TYPE *dx = dest->x_edges;
  UNIT_TYPE *dy = dest->y_edges;
  UNIT_TYPE *dz = dest->z_edges;
  UNIT_TYPE *x = region->x_edges;
  UNIT_TYPE *y = region->y_edges;
  UNIT_TYPE *z = region->z_edges;

  for (; x < region->x_edges + region->x_size; ++x)
    {
      /* Is this X edge redundant wrt Y and Z?  */
      if (edge_redundant_p (region, x, region->x_edges,
			    region->y_edges,
			    region->y_edges + region->y_size,
			    region->z_edges,
			    region->z_edges + region->z_size,
			    X_SCALE, Y_SCALE, Z_SCALE))
	continue;
      *dx++ = *x;
    }

  for (; y < region->y_edges + region->y_size; ++y)
    {
      /* Is this Y edge redundant wrt X and Z?  */
      if (edge_redundant_p (region, y, region->y_edges,
			    region->x_edges,
			    region->x_edges + region->x_size,
			    region->z_edges,
			    region->z_edges + region->z_size,
			    Y_SCALE, X_SCALE, Z_SCALE))
	continue;
      *dy++ = *y;
    }

  for (; z < region->z_edges + region->z_size; ++z)
    {
      /* Is this Z edge redundant wrt X and Y?  */
      if (edge_redundant_p (region, z, region->z_edges,
			    region->x_edges,
			    region->x_edges + region->x_size,
			    region->y_edges,
			    region->y_edges + region->y_size,
			    Z_SCALE, X_SCALE, Y_SCALE))
	continue;
      *dz++ = *z;
    }

  /* Initialize the destination shape.  */

  dest->x_size = (dx - dest->x_edges);
  dest->y_size = (dy - dest->y_edges);
  dest->z_size = (dz - dest->z_edges);

  /* Allocate or resize solids array.  */
  if (resize_solids (dest, BITSET_SIZE (dest->x_size,
					dest->y_size,
					dest->z_size)))
    return 1;

  for (x = dest->x_edges; x < dx; ++x)
    {
      UNIT_TYPE *src_x = bisect (region->x_edges, region->x_size, *x);
      int x_index, dx_index;
      assert (src_x && *src_x == *x);
      x_index = XINDEX (src_x, region->x_edges);
      dx_index = XINDEX (x, dest->x_edges);

      for (y = dest->y_edges; y < dy; ++y)
	{
	  UNIT_TYPE *src_y = bisect (region->y_edges, region->y_size, *y);
	  int y_index, dy_index;
	  assert (src_y && *src_y == *y);
	  y_index = YINDEX (src_y, region->y_edges);
	  dy_index = YINDEX (y, dest->y_edges);

	  for (z = dest->z_edges; z < dz; ++z)
	    {
	      UNIT_TYPE *src_z = bisect (region->z_edges, region->z_size, *z);
	      int z_index, dz_index, index, d_index;
	      assert (src_z && *src_z == *z);
	      z_index = ZINDEX (src_z, region->z_edges);
	      dz_index = ZINDEX (z, dest->z_edges);
	      index = z_index + y_index + x_index;
	      d_index = dz_index + dy_index + dx_index;

	      if (IS_OCCUPIED_P (region, index))
		MARK_OCCUPIED (dest, d_index);
	    }
	}
    }
  return 0;
}



/* Region utilities.  */

/* Quickly create a read-only region in REGION from the provided
   AABB.  */

/* Bitmask indicating that two values exist on each axis the first of
   which is solid.  */
static unsigned int aabb_index[BITSET_SIZE (2, 2, 2)] = {
  0x1,
};

static void
region_init_from_AABB (region, aabb)
     struct cuboid_region *region;
     AABB *aabb;
{
  assert (AABB_VALID_P (aabb));
  region->solids = aabb_index;
  region->b_size = BITSET_SIZE (2, 2, 2);
  region->x_size = 2;
  region->y_size = 2;
  region->z_size = 2;
  region->x_edges[0] = aabb->x1;
  region->x_edges[1] = aabb->x2;
  region->y_edges[0] = aabb->y1;
  region->y_edges[1] = aabb->y2;
  region->z_edges[0] = aabb->z1;
  region->z_edges[1] = aabb->z2;
  assert (IS_OCCUPIED_P (region, 0));
}

/* Intersect REGION with AABB, placing the result in DEST.  Value is 1
   if the resultant region is excessively complex, and 0
   otherwise.  */

int
region_intersect (dest, region, aabb)
     struct cuboid_region *RESTRICT dest;
     struct cuboid_region *region;
     AABB *aabb;
{
  struct cuboid_region src;
  region_init_from_AABB (&src, aabb);
  return region_op (dest, region, &src, OP_AND);
}

/* Subtract AABB from REGION, placing the result in DEST.  Value is 1
   if the resultant region would be excessively complex, and 0
   otherwise.  */

int
region_subtract (dest, region, aabb)
     struct cuboid_region *RESTRICT dest;
     struct cuboid_region *region;
     AABB *aabb;
{
  struct cuboid_region src;
  region_init_from_AABB (&src, aabb);
  return region_op (dest, region, &src, OP_SUB);
}

/* Union AABB with REGION, placing the result in DEST.  Value is 1 if
   the resultant region would be excessively complex, and 0
   otherwise.  */

int
region_union (dest, region, aabb)
     struct cuboid_region *RESTRICT dest;
     struct cuboid_region *region;
     AABB *aabb;
{
  struct cuboid_region src;
  region_init_from_AABB (&src, aabb);
  return region_op (dest, region, &src, OP_OR);
}



/* Region cross-sections (a.k.a. faces).  */

/* Create a region in REGION consisting exclusively of the values
   along one axis NORMAL_AXIS at POS, spanning POS to -POS on the same
   axis.  */

int
region_select_face (face, region, normal_axis, pos)
     struct cuboid_region *face;
     struct cuboid_region *region;
     int normal_axis;
     UNIT_TYPE pos;
{
  UNIT_TYPE *m, *a, *b;
  UNIT_TYPE *m_end, *a_end, *b_end;
  UNIT_TYPE *basis, *basis_other;
  int m_index, a_index, b_index;
  int a_size, b_size;
  UNIT_TYPE *out_a, *out_b;
  int m_index_1, m_index_2;

  switch (normal_axis)
    {
    case AXIS_X:
      m = region->x_edges;
      a = region->y_edges;
      b = region->z_edges;
      m_end = m + region->x_size;
      a_end = a + region->y_size;
      b_end = b + region->z_size;
      m_index = EDGES_PER_AXIS * EDGES_PER_AXIS;
      a_index = EDGES_PER_AXIS;
      b_index = 1;
      out_a = face->y_edges;
      out_b = face->z_edges;
      break;

    case AXIS_Y:
      m = region->y_edges;
      a = region->x_edges;
      b = region->z_edges;
      m_end = m + region->y_size;
      a_end = a + region->x_size;
      b_end = b + region->z_size;
      m_index = EDGES_PER_AXIS;
      a_index = EDGES_PER_AXIS * EDGES_PER_AXIS;
      b_index = 1;
      out_a = face->x_edges;
      out_b = face->z_edges;
      break;

    case AXIS_Z:
      m = region->z_edges;
      a = region->x_edges;
      b = region->y_edges;
      m_end = m + region->z_size;
      a_end = a + region->x_size;
      b_end = b + region->y_size;
      m_index = 1;
      a_index = EDGES_PER_AXIS * EDGES_PER_AXIS;
      b_index = EDGES_PER_AXIS;
      out_a = face->x_edges;
      out_b = face->y_edges;
      break;
    }

  /* Number of edges along the other two axes.  */
  a_size = 0;
  b_size = 0;

  /* Locate a value along M matching POS.  */
  basis = bisect (m, m_end - m, pos);
  if (!basis)
    goto fill_region;

  assert (*basis <= pos);

  /* If there is an edge at POS, its on state is governed not only by
     itself but also its previous value.  */
  basis_other = ((*basis == pos && basis != m)
		 ? basis - 1 : basis);

  /* Iterate over A and B, the remaining axes.  */

  {
    UNIT_TYPE *a1, *b1;
    m_index_1 = (basis - m) * m_index;
    m_index_2 = (basis_other - m) * m_index;

    for (a1 = a; a1 < a_end; ++a1)
      out_a[a_size++] = *a1;

    for (b1 = b; b1 < b_end; ++b1)
      out_b[b_size++] = *b1;
  }

 fill_region:

  if (!a_size || !b_size)
    {
      face->x_size = 0;
      face->y_size = 0;
      face->z_size = 0;
      return 0;
    }

  switch (normal_axis)
    {
    case AXIS_X:
      face->y_size = a_size;
      face->z_size = b_size;

      /* Initialize face->x_axis with pos and -pos.  */
      face->x_size = 2;
      face->x_edges[0] = MIN (pos, -pos);
      face->x_edges[1] = MAX (pos, -pos);
      break;

    case AXIS_Y:
      face->x_size = a_size;
      face->z_size = b_size;

      /* Initialize face->y_axis with pos and -pos.  */
      face->y_size = 2;
      face->y_edges[0] = MIN (pos, -pos);
      face->y_edges[1] = MAX (pos, -pos);
      break;

    case AXIS_Z:
      face->x_size = a_size;
      face->y_size = b_size;

      /* Initialize face->z_axis with pos and -pos.  */
      face->z_size = 2;
      face->z_edges[0] = MIN (pos, -pos);
      face->z_edges[1] = MAX (pos, -pos);
      break;

    default:
      UNREACHABLE;
    }

  /* Mark everything along the lesser edge solid.  */
  if (resize_solids (face, BITSET_SIZE (face->x_size,
					face->y_size,
					face->z_size)))
    return 1;
  else
    {
      int a1, b1;

      for (b1 = 0; b1 < b_size; ++b1)
	{
	  int b_index_1 = b1 * b_index;

	  for (a1 = 0; a1 < a_size; ++a1)
	    {
	      int a_index_1 = a1 * a_index;

	      if (IS_OCCUPIED_P (region, (m_index_1 + a_index_1
					  + b_index_1))
		  || IS_OCCUPIED_P (region, (m_index_2 + a_index_1
					     + b_index_1)))
		MARK_OCCUPIED (face, a_index_1 + b_index_1);
	    }
	}
      return 0;
    }
}

/* Local Variables: */
/* c-noise-macro-names: ("RESTRICT" "PROTO") */
/* End: */
