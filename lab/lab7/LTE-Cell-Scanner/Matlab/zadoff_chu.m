function y=zadoff_chu(l,i)

% y=zadoff_chu(l,i);
%
% Return the zadoff-chu sequence of length 'l' with index 'i'.
%
% Normally, 'l' and 'i' should be relatively prime.

% Copyright 2012 Evrytania LLC (http://www.evrytania.com)
%
% Written by James Peroulas <james@evrytania.com>
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

error(chk_param(l,'l','scalar','real','integer','>',1));
error(chk_param(i,'i','scalar','real','integer','>',0,'<=',l-1));

if (bitand(l,1))
  y=exp(-j*i*pi/l*(0:l-1).*(1:l));
else
  y=exp(-j*i*pi/l*(0:l-1).^2);
end

