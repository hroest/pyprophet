# encoding: latin-1
cimport cython
cimport libc.stdlib
cimport numpy as np
import numpy as np


@cython.boundscheck(False)
@cython.wraparound(False)
def find_nearest_matches(np.float64_t[:] basis, np.float64_t[:] sample_points, use_sort_order=1):
    cdef size_t num_basis = basis.shape[0]
    cdef size_t num_samples = sample_points.shape[0]
    result = np.zeros((num_samples,), dtype=np.int64)
    cdef np.int64_t[:] view = result
    cdef size_t i, best_j
    cdef size_t low, high, mid
    cdef double sp_i, best_dist, dist
    cdef int sort_order

    if not use_sort_order:
        for i in range(num_samples):
            sp_i = sample_points[i]
            best_j = 0
            best_dist = abs(basis[0] - sp_i)
            for j in range(1, num_basis):
                dist = abs(basis[j] - sp_i)
                if dist < best_dist:
                    best_dist = dist
                    best_j = j
            view[i] = best_j
        return result

    sort_order = find_sort_order(basis)
    for i in range(num_samples):
        sp_i = sample_points[i]
        if sort_order == 0:
            best_j = 0
            best_dist = abs(basis[0] - sp_i)
            for j in range(1, num_basis):
                dist = abs(basis[j] - sp_i)
                if dist < best_dist:
                    best_dist = dist
                    best_j = j
        elif sort_order == 1:
            low = 0
            high = num_basis - 1
            best_j = -1
            if basis[low] == sp_i:
                best_j = low
            elif basis[high] == sp_i:
                best_j = high
            else:
                while low < high - 1:
                    mid = (low + high) / 2
                    if basis[mid] == sp_i:
                        best_j = mid
                    if basis[mid] < sp_i:
                        low = mid
                    else:
                        high = mid
                if best_j == -1:
                    if abs(basis[low] - sp_i) < abs(basis[high] - sp_i):
                        best_j = low
                    else:
                        best_j = high
            # find first match in list !
            while best_j > 0:
                if basis[best_j - 1] == basis[best_j]:
                    best_j = best_j - 1
                else:
                    break
        else:
            low = 0
            high = num_basis - 1
            best_j = -1
            if basis[low] == sp_i:
                best_j = low
            elif basis[high] == sp_i:
                best_j = high
            else:
                while low < high - 1:
                    mid = (low + high) / 2
                    if basis[mid] == sp_i:
                        best_j = mid
                        break
                    if basis[mid] > sp_i:
                        low = mid
                    else:
                        high = mid
                if best_j == -1:
                    if abs(basis[low] - sp_i) < abs(basis[high] - sp_i):
                        best_j = low
                    else:
                        best_j = high
            # find first match in list:
            while best_j > 0:
                if basis[best_j - 1] == basis[best_j]:
                    best_j = best_j - 1
                else:
                    break

        view[i] = best_j
    return result


cdef int find_sort_order(np.float64_t[:] basis):
    # 0: unsorted
    # 1: ascending
    # 2: descending
    cdef size_t i, n
    n = basis.shape[0]
    if n <= 1:
        return 0
    i = 0
    while i < n - 1 and basis[i] == basis[i + 1]:
        i += 1
    if i == n - 1:
        return 1   # or -1 as list is constant
    if basis[i] < basis[i + 1]:
        for i in range(i, n - 1):
            if basis[i] > basis[i + 1]:
                return 0
        return 1
    else:
        for i in range(i, n - 1):
            if basis[i] < basis[i + 1]:
                return 0
        return -1

@cython.boundscheck(False)
@cython.wraparound(False)
def count_num_positives(np.float64_t[:] values):
    cdef size_t n = values.shape[0]
    cdef np.float64_t[:] inp_view = values
    cdef size_t i0, i1, c
    result = np.zeros_like(values, dtype=np.int64)
    cdef np.int64_t[:] res_view = result
    i0 = i1 = 0
    c = n
    while i0 < n:
        while i1 < n and inp_view[i0] == inp_view[i1]:
            res_view[i1] = c
            i1 += 1
        c -= 1
        i0 += 1
    return result

@cython.boundscheck(False)
@cython.wraparound(False)
def find_top_ranked(np.int64_t[:] tg_ids, np.float64_t[:] scores):
    cdef size_t n = scores.shape[0]
    flags = np.zeros((n,), dtype=np.int64)
    cdef np.int64_t[:] view = flags
    cdef double current_max = scores[0]
    cdef size_t current_imax = 0
    cdef size_t current_tg_id = tg_ids[0]
    cdef size_t current_write_i = 0
    cdef size_t i
    cdef size_t id_
    cdef double sc
    for i in range(tg_ids.shape[0]):
        id_ = tg_ids[i]
        sc = scores[i]
        if id_ != current_tg_id:
            current_tg_id = id_
            view[current_imax] = 1
            current_write_i += 1
            current_max = sc
            current_imax = i
            continue
        if sc > current_max:
            current_max = sc
            current_imax = i
    view[current_imax] = 1
    return flags

cdef partial_rank(np.float64_t[:] v, size_t imin, size_t imax, np.int64_t[:] ranks):
    """ imax is exclusive """
    cdef size_t * ix = <size_t * > libc.stdlib.malloc((imax - imin) * sizeof(size_t))
    cdef size_t i, j, pos
    for i in range(imax - imin):
        ix[i] = i + imin
    for i in range(imax - imin - 1):
        pos = i
        for j in range(i + 1, imax - imin):
            if v[ix[j]] > v[ix[pos]]:
                pos = j
        ix[i], ix[pos] = ix[pos], ix[i]

    for j in range(imax - imin):
        ranks[ix[j]] = j + 1
    libc.stdlib.free(ix)


@cython.boundscheck(False)
@cython.wraparound(False)
def rank(np.int64_t[:] tg_ids, np.float64_t[:] scores):
    cdef size_t n = tg_ids.shape[0]
    result = np.zeros((n,), dtype=np.int64)
    cdef np.int64_t[:] ranks = result
    cdef size_t imin = 0
    cdef size_t imax
    cdef np.float64_t g0
    while imin < n:
        imax = imin + 1
        g0 = tg_ids[imin]
        while imax < n and tg_ids[imax] == g0:
            imax += 1
        partial_rank(scores, imin, imax, ranks)
        imin = imax
    return result
