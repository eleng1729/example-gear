% This function parses an xml plist file, as defined by Apple. This is the
% output for exported ROIs from Osirix.
% Unfortunately, this is not a simple conversion because Apple chose a very
% strange mapping between plists and xml. So I flatten it out to a more
% appropriate format for a strcuture. 
function plist = parseApplePlistXml(filename)

% We'll use the xml2struct function and parse through.
% This is needed because Apple plist files are weird xml. In each <dict>
% element, there are <key> followed by <something>.
x = xml2struct(filename);

plist = [];
plist = parse_item_recursive(x(2).Children(2));




function out = parse_item_recursive(x);

switch(x.Name)
    
    case 'dict'
        dict = x.Children;
        %fprintf('dict with %d keys\n', (size(x.Children,2)-1)/4);
        
        % Loop over these
        jdx = 1;
        while jdx<size(dict,2)
            % Skip the first
            jdx= jdx + 1;
            
            % Then get the key
            keyname = dict(jdx).Children.Data;
            %fprintf('Found keyname %s\n', keyname);
            jdx = jdx + 1;
            jdx = jdx + 1;
            
            % Get value
            val = parse_item_recursive(dict(jdx));
            
            % Set the value
            out.(keyname) = val;
            
            jdx = jdx + 1;
            
        end
        
    case 'array'
        % Just parse the children. Skip the every-other bogus elements
        numelements = (size(x.Children,2)-1)/2;
        for idx =1:numelements
            tmp = parse_item_recursive(x.Children(idx*2));
            out(idx) = tmp;
        end
        
    case '#text'
        fprintf('skipping #text\n');
        
    case 'integer'
        out = x.Children.Data;
        
    case 'real'
        out = x.Children.Data;
        
    case 'string'
        out = {x.Children.Data};
        
    otherwise
        fprintf('unknown element %s\n', x.Name);
        out = '';
        
end



