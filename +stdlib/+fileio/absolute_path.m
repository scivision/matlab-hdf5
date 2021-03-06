function abspath = absolute_path(p)
% path need not exist, but absolute path is returned
%
% NOTE: some network file systems are not resolvable by Matlab Java
% subsystem, but are sometimes still valid--so return
% unmodified path if this occurs.
%
% Copyright (c) 2020 Michael Hirsch (MIT License)
arguments
  p (1,:) string
end

import stdlib.fileio.expanduser
import stdlib.fileio.is_absolute_path

% have to expand ~ first
p = expanduser(p);

if ~is_absolute_path(p)
  % otherwise the default is Documents/Matlab, which is probably not wanted.
  p = fullfile(pwd, p);
end

abspath = p;

for i = 1:length(abspath)
  abspath(i) = string(java.io.File(abspath(i)).getCanonicalPath());
end

end % function
