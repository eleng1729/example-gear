% XML Parsing helper
% Filename must be full path!
function doc = load_xml_doc(filename)
import javax.xml.parsers.*

% First load the doc and parse it
factory = DocumentBuilderFactory.newInstance();
factory.setNamespaceAware(true);
builder = factory.newDocumentBuilder();
doc = builder.parse(filename);