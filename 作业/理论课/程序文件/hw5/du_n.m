% Zadoff序列的生成函数，输入参数为u值
function [du_n] = du_n(root_index)
    du_n = zeros(1, 62);  %因为首位不能是0，我们只能从1开始
    n = 0;
    while n <= 30
        du_n(n+1)=exp(-1j*pi*(root_index)*n*(n+1)/63);
        n = n + 1;
    end
    for n = 31:1:61
        du_n(n+1)=exp(-1j*pi*(root_index)*(n+1)*(n+2)/63);
    end
end

