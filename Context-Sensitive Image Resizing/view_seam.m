function view_seam(im,seam,seamDirection)
    if seamDirection == "HORIZONTAL"
        for c = 1:size(im, 2)
            im(seam(c), c, 1) = 255;
            im(seam(c), c, 2) = 0;
            im(seam(c), c, 3) = 255;
        end
    elseif seamDirection == "VERTICAL"
        for r = 1:size(im, 1)
            im(r, seam(r), 1) = 255;
            im(r, seam(r), 2) = 0;
            im(r, seam(r), 3) = 255;
        end
    else
    end
    
    imshow(im);
end