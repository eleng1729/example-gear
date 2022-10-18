function xpath = get_xpath()
import javax.xml.xpath.*

xpf = XPathFactory.newInstance();
xpath = xpf.newXPath();