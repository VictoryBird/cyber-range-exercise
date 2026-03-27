package mil.valdoria.mnd.portal.vo;

/**
 * SearchVO — 통합 검색 파라미터 바인딩 객체
 *
 * [취약점] VULN-D1-01: Spring4Shell (CVE-2022-22965)
 *
 * 이 POJO는 Spring MVC의 DataBinder를 통해 HTTP 요청 파라미터와 자동 바인딩된다.
 * Spring 5.3.17 + JDK 11 환경에서 class.module.classLoader 체인을 통해
 * Tomcat의 내부 객체(AccessLogValve)에 접근 가능하며,
 * 이를 통해 임의 파일 생성(웹셸)이 가능하다.
 *
 * [올바른 구현] Spring 5.3.18+로 업그레이드하면 class 속성 접근이 차단됨.
 */
public class SearchVO {

    /** 검색 키워드 */
    private String keyword;

    /** 검색 카테고리 (notice, download, all) */
    private String category;

    /** 페이지 번호 */
    private int pageNo;

    /** 페이지 크기 */
    private int pageSize = 10;

    // --- Getters / Setters ---

    public String getKeyword() {
        return keyword;
    }

    public void setKeyword(String keyword) {
        this.keyword = keyword;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public int getPageNo() {
        return pageNo;
    }

    public void setPageNo(int pageNo) {
        this.pageNo = pageNo;
    }

    public int getPageSize() {
        return pageSize;
    }

    public void setPageSize(int pageSize) {
        this.pageSize = pageSize;
    }
}
