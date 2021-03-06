import pdb

def test_regression_test():
    import pyprophet.config
    import pyprophet.pyprophet
    import os.path
    import numpy 

    pyprophet.config.CONFIG["is_test"] = True
    path = os.path.join(os.path.abspath(os.path.dirname(__file__)), "test_data.txt")
    (res, __, tab), __  = pyprophet.pyprophet.PyProphet().process_csv(path, "\t")

    tobe =  [ 7.13743586,-0.29133736,-0.34778976,-1.33578699, None,
              None, None, None, None]

    cutoffs = res.cutoff.values

    assert all(c is None for c in cutoffs[4:])

    numpy.testing.assert_array_almost_equal(cutoffs[:4], tobe[:4])

    assert list(tab.columns)[-3:] == ["d_score", "m_score", "peak_group_rank"]

    ranks = list(tab.peak_group_rank.values)[:10]
    assert ranks == [1, 3, 7, 6, 2, 4, 5, 1, 3, 5], ranks

    ranks = list(tab.peak_group_rank.values)[-10:]
    assert ranks == [12, 2, 15, 9, 8, 11, 4, 16, 14, 10], ranks

    tobe = [5.54973193, -1.59305365, -7.43544856, -4.75434466, -0.99465366]
    numpy.testing.assert_array_almost_equal(tab.d_score.values[:5], tobe)

    tobe = [-3.65461483, -1.52916888, -5.10635037, -4.08469665, -3.46694394]
    numpy.testing.assert_array_almost_equal(tab.d_score.values[-5:], tobe)

    tobe = [8.83676159e-09, 3.73491421e-02,   3.73491421e-02, 3.73491421e-02,
            2.95475612e-02]

    numpy.testing.assert_array_almost_equal(tab.m_score.values[:5], tobe)

    tobe = [ 0.03734914,  0.03734914,  0.03734914,  0.03734914,  0.03734914]
    numpy.testing.assert_array_almost_equal(tab.m_score.values[-5:], tobe)
