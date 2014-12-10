# -*- mode: python -*-

import pandas
import numpy
import sklearn.lda
import sklearn.utils
import sklearn.utils.sparsetools
import sklearn.utils.sparsetools._graph_validation

block_cipher = None

import inspect
# the build folder should be the first path on the stack
dirname = os.path.dirname(os.path.abspath( inspect.stack()[0][1] ))
pyprophet_exe = os.path.join(os.path.join(os.path.join(dirname, ".."), "pyprophet"), "main.py")

a = Analysis([pyprophet_exe],
             pathex=['/home/hr/projects/pyprophet/building'],
             hiddenimports=[],
             hookspath=None,
             runtime_hooks=None,
             cipher=block_cipher)

a.datas.append(("sklearn/utils/sparsetools/_graph_validation.py", os.path.join(os.path.dirname(sklearn.__file__), 'utils/sparsetools/_graph_validation.py'),"BINARY"))
a.datas.append(("sklearn/utils/sparsetools/_graph_tools.so", os.path.join(os.path.dirname(sklearn.__file__), 'utils/sparsetools/_graph_tools.so'),"BINARY"))

print "=================="
print a.datas[-1]

pyz = PYZ(a.pure,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          exclude_binaries=True,
          name='main',
          debug=False,
          strip=None,
          upx=True,
          console=True )
coll = COLLECT(exe,
               a.binaries,
               a.zipfiles,
               a.datas,
               strip=None,
               upx=True,
               name='main')
