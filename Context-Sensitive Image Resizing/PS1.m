% Load matrix and call all functions %
function PS1()
    load("PS0_A.mat", "A");
    a(A);
    b(A);
    c(A);
    d(A);
    e(A);
end

% Plot all 10,000 values of A in descending order %
function a(A)
    % Reshape A into a 1x10,000 matrix and sort into descending order %
    A = reshape(A,[1, length(A)^2]);
    A = sort(A);
    A = A((end:-1:1));
    
    % Display A as scatterplot and save %
    fig = plot(A);
    title('Sorted Values of A'), xlabel('Linear Index of A'), 
        ylabel('Value From 0-255'), grid on;
    axis([0 10000 0 255]);
    saveas(fig, "PS0_Q1_a.png");
end

function b(A)
    % Reshape A into a 1x10,000 matrix %
    A = reshape(A,[1, length(A)^2]);
    
    % Display A as histogram with 10 equally sized bins and save %
    fig = histogram(A, 10);
    title('Histogram of A'), ylabel('Frequency'), 
        xlabel('Value From 0-255 (In 10 Equal Bins)'), grid on;
    axis([0 255 0 1100]);
    saveas(fig, "PS0_Q1_b.png");
end

function c(A)
    % Save Z as bottom left quadrant of A %
    Z = A(51:100, 1:50);
    
    % Display Z as image and save %
    fig = imagesc(Z);
    title('Image Representation of Z'), ylabel('Row Index'), 
        xlabel('Column Index');
    saveas(fig, "PS0_Q1_c.png");
end

function d(A)
    % Save W as matrix A with each element subtracted by mean A %
    W = A - (sum(sum(A))/10000);
    
    % Display W as image and save %
    fig = imagesc(W);
    title('Image Representation of W'), ylabel('Row Index'), 
        xlabel('Column Index');
    saveas(fig, "PS0_Q1_d.png");
end

function e(A)
    % Set t to mean of A %
    t = (sum(sum(A))/10000);
    
    % Set red to be 255 when value > mean and 0 otherwise %
    % Set blue and green to be 0 for all indices %
    red = (A > t) .* 255;
    blue = zeros(100,100);
    green = zeros(100,100);
    
    % Display RGB matrices as image and save %
    fig = imshow(cat(3,red,blue,green)); 
    title('Image Representation of A'), ylabel('Row Index'), 
        xlabel('Column Index');
    saveas(fig, "PS0_Q1_e.png");
end