classdef TestNetCDF < matlab.unittest.TestCase

properties
TestData
end

properties (TestParameter)
type = {'single', 'double', 'int32', 'int64'}
vars = {'A0', 'A1', 'A2', 'A3', 'A4'}
end


methods (TestMethodSetup)

function setup_file(tc)
import stdlib.hdf5nc.ncsave
import matlab.unittest.constraints.IsFile

A0 = 42.;
A1 = [42.; 43.];
A2 = magic(4);
A3 = A2(:,1:3,1);
A3(:,:,2) = 2*A3;
A4(:,:,:,5) = A3;

tc.TestData.A0 = A0;
tc.TestData.A1 = A1;
tc.TestData.A2 = A2;
tc.TestData.A3 = A3;
tc.TestData.A4 = A4;

basic = tempname + ".nc";
tc.TestData.basic = basic;

% create test data first, so that parallel tests works
ncsave(basic, 'A0', A0)
ncsave(basic, 'A1', A1)
ncsave(basic, 'A2', A2, "dims", {'x2', size(A2,1), 'y2', size(A2,2)})
ncsave(basic, 'A3', A3, "dims", {'x3', size(A3,1), 'y3', size(A3,2), 'z3', size(A3,3)})
ncsave(basic, 'A4', A4, "dims", {'x4', size(A4,1), 'y4', size(A4,2), 'z4', size(A4,3), 'w4', size(A4,4)})

tc.assumeThat(basic, IsFile)
end
end


methods (TestMethodTeardown)
function cleanup(tc)
delete(tc.TestData.basic)
end
end


methods (Test)
function test_get_variables(tc)
import stdlib.hdf5nc.ncvariables
basic = tc.TestData.basic;

tc.verifyEqual(sort(ncvariables(basic)), ["A0", "A1", "A2", "A3", "A4"])
end


function test_exists(tc, vars)
import stdlib.hdf5nc.ncexists
import matlab.unittest.constraints.IsScalar
basic = tc.TestData.basic;

e = ncexists(basic, vars);
tc.verifyThat(e, IsScalar)
tc.verifyTrue(e)

% vector
e = ncexists(basic, [vars, "oops"]);
tc.verifyTrue(isrow(e))
tc.verifyEqual(e, [true, false])

end


function test_size(tc)
import stdlib.hdf5nc.ncsize
import matlab.unittest.constraints.IsScalar
basic = tc.TestData.basic;

s = ncsize(basic, 'A0');
tc.verifyThat(s, IsScalar)
tc.verifyEqual(s, 1)

s = ncsize(basic, 'A1');
tc.verifyThat(s, IsScalar)
tc.verifyEqual(s, 2)

s = ncsize(basic, 'A2');
tc.verifyTrue(isvector(s))
tc.verifyEqual(s, [4,4])

s = ncsize(basic, 'A3');
tc.verifyTrue(isvector(s))
tc.verifyEqual(s, [4,3,2])

s = ncsize(basic, 'A4');
tc.verifyTrue(isvector(s))
tc.verifyEqual(s, [4,3,2,5])

end


function test_read(tc)
import matlab.unittest.constraints.IsScalar
basic = tc.TestData.basic;

s = ncread(basic, '/A0');
tc.verifyThat(s, IsScalar)
tc.verifyEqual(s, 42)

s = ncread(basic, '/A1');
tc.verifyTrue(isvector(s))
tc.verifyEqual(s, tc.TestData.A1)

s = ncread(basic, '/A2');
tc.verifyTrue(ismatrix(s))
tc.verifyEqual(s, tc.TestData.A2)

s = ncread(basic, '/A3');
tc.verifyEqual(ndims(s), 3)
tc.verifyEqual(s, tc.TestData.A3)

s = ncread(basic, '/A4');
tc.verifyEqual(ndims(s), 4)
tc.verifyEqual(s, tc.TestData.A4)
end


function test_coerce(tc, type)
import stdlib.hdf5nc.ncsave
import matlab.unittest.constraints.IsFile
basic = tc.TestData.basic;

vn = type;

ncsave(basic, vn, 0, "type", type)

tc.assumeThat(basic, IsFile)

tc.verifyClass(ncread(basic, vn), type)
end


function test_rewrite(tc)
import stdlib.hdf5nc.ncsave
import matlab.unittest.constraints.IsFile
basic = tc.TestData.basic;

ncsave(basic, 'A2', 3*magic(4))

tc.assumeThat(basic, IsFile)
tc.verifyEqual(ncread(basic, 'A2'), 3*magic(4))
end

function test_no_char_string(tc)
import stdlib.hdf5nc.ncsave
tc.verifyError(@() ncsave(tc.TestData.basic, "/a_string", "hello"), 'MATLAB:validators:mustBeNumeric')

end

function test_file_missing(tc)

[~,badname] = fileparts(tempname);
tc.verifyError(@() stdlib.hdf5nc.ncsave(badname,"bad",0), 'hdf5nc:ncsave:fileNotFound')
end

function test_real_only(tc)
import stdlib.hdf5nc.ncsave
basic = tc.TestData.basic;

tc.verifyError(@() ncsave(basic, "bad_imag", 1j), 'MATLAB:validators:mustBeReal')
tc.verifyError(@() ncsave(basic, "", 0), 'MATLAB:validators:mustBeNonzeroLengthText')
end

end

end
