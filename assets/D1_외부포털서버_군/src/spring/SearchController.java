package mil.valdoria.mnd.portal.controller;

import mil.valdoria.mnd.portal.vo.SearchVO;
import mil.valdoria.mnd.portal.vo.SearchResultVO;
import mil.valdoria.mnd.portal.service.SearchService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import java.util.List;

/**
 * SearchController — 통합 검색 컨트롤러
 *
 * [취약점] VULN-D1-01: Spring4Shell (CVE-2022-22965)
 *
 * 이 컨트롤러는 SearchVO 객체에 HTTP 요청 파라미터를 자동 바인딩(@ModelAttribute 암시적)한다.
 * Spring Framework 5.3.17 + JDK 11 + WAR on Tomcat 9 조건에서,
 * 공격자는 class.module.classLoader 경로를 통해 Tomcat의 AccessLogValve 속성을
 * 조작하여 임의 JSP 파일(웹셸)을 생성할 수 있다.
 *
 * [올바른 구현] Spring Framework 5.3.18 이상으로 업그레이드하거나,
 *   DataBinder에 disallowedFields를 설정하여 class.* 바인딩을 차단해야 한다.
 *   예: @InitBinder public void initBinder(WebDataBinder binder) {
 *       binder.setDisallowedFields("class.*", "Class.*", "*.class.*", "*.Class.*");
 *   }
 *
 * 취약 조건:
 *   - Spring Framework 5.3.17 (5.3.18 미만)
 *   - JDK 11 (JDK 9+에서 Module 클래스 노출)
 *   - WAR 배포 (Tomcat 서블릿 컨테이너)
 *   - POJO 파라미터 바인딩 사용
 */
@Controller
public class SearchController {

    @Autowired
    private SearchService searchService;

    /**
     * 통합 검색 처리
     *
     * [취약점] searchVO 파라미터에 자동 바인딩이 적용됨.
     * Spring 5.3.17에서 class.module.classLoader.resources.context.parent.pipeline.first.*
     * 경로를 통한 Tomcat ClassLoader 접근이 가능하여 Spring4Shell 공격에 노출됨.
     *
     * 공격 페이로드 예시:
     *   class.module.classLoader.resources.context.parent.pipeline.first.pattern=<웹셸코드>
     *   class.module.classLoader.resources.context.parent.pipeline.first.suffix=.jsp
     *   class.module.classLoader.resources.context.parent.pipeline.first.directory=webapps/ROOT
     *   class.module.classLoader.resources.context.parent.pipeline.first.prefix=cmd
     *   class.module.classLoader.resources.context.parent.pipeline.first.fileDateFormat=
     */
    @RequestMapping(value = "/search.do", method = {RequestMethod.GET, RequestMethod.POST})
    public String search(SearchVO searchVO, Model model) {
        // SearchVO에 파라미터가 자동 바인딩됨 → Spring4Shell 취약
        List<SearchResultVO> results = searchService.search(searchVO);
        model.addAttribute("results", results);
        model.addAttribute("keyword", searchVO.getKeyword());
        model.addAttribute("totalCount", results.size());
        return "search/searchResult";
    }
}
